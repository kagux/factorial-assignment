require "spec_helper"
require_relative "../../support/parts_setup_context"

RSpec.describe Parts::CompatibilityService do
  include_context "parts setup"
  let (:described_class) { Parts::CompatibilityService.new(cache: Cache::NullCache.new) }
  
  describe ".get_compatible_variants_ids" do

    it "returns all variants of the target part when no selected variants are provided" do
      result = described_class.get_compatible_variants_ids(
        product: product,
        selected_variants: [],
        target_variants: finish_part.part_variants,
      )

      expect(result).to contain_exactly(
        matte_finish_variant.id,
        glossy_finish_variant.id,
        chrome_finish_variant.id
      )
    end

    it "returns all variants of the target part with no compatibility rules defined" do
      result = described_class.get_compatible_variants_ids(
        product: product,
        selected_variants: [diamond_small_frame],
        target_variants: finish_part.part_variants,
      )

      expect(result).to contain_exactly(
        matte_finish_variant.id,
        glossy_finish_variant.id,
        chrome_finish_variant.id
      )
    end

    context "with INCLUDE variant compatibility rules" do
      before do
        # Create rule: Diamond frames can only have Glossy or Chrome finishes
        create(:part_variant_compatibility,
               product: product,
               part_variant_1: diamond_small_frame,
               part_variant_2: glossy_finish_variant,
               compatibility_type: "INCLUDE")
        create(:part_variant_compatibility,
               product: product,
               part_variant_1: diamond_small_frame,
               part_variant_2: chrome_finish_variant,
               compatibility_type: "INCLUDE")
      end

      it "returns only variants with INCLUDE rules" do
        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [diamond_small_frame],
          target_variants: finish_part.part_variants,
        )

        expect(result).to contain_exactly(glossy_finish_variant.id, chrome_finish_variant.id)
      end

      it "returns same variants when rule is defined in reverse order" do
        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [glossy_finish_variant],
          target_variants: frame_part.part_variants,
        )

        expect(result).to contain_exactly(diamond_small_frame.id)
      end

      it "ignores inactive compatibility rules" do
        create(:part_variant_compatibility,
               product: product,
               part_variant_1: diamond_small_frame,
               part_variant_2: matte_finish_variant,
               compatibility_type: "INCLUDE",
               active: false)

        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [diamond_small_frame],
          target_variants: finish_part.part_variants,
        )

        expect(result).to contain_exactly(glossy_finish_variant.id, chrome_finish_variant.id)
      end

      it "scopes compatibility rules to a product" do
        result = described_class.get_compatible_variants_ids(
          product: create(:product),
          selected_variants: [diamond_small_frame],
          target_variants: finish_part.part_variants,
        )

        expect(result).to be_empty
      end
    end

    context "with EXCLUDE variant compatibility rules" do
      before do
        # Create rule: Full suspension frames cannot have Chrome finish
        create(:part_variant_compatibility,
               product: product,
               part_variant_1: suspension_small_frame,
               part_variant_2: chrome_finish_variant,
               compatibility_type: "EXCLUDE")
      end

      it "excludes variants with EXCLUDE rules" do
        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [suspension_small_frame],
          target_variants: finish_part.part_variants,
        )

        expect(result).to contain_exactly(matte_finish_variant.id, glossy_finish_variant.id)
      end

      it "excludes variants with EXCLUDE rules in reverse order" do
        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [chrome_finish_variant],
          target_variants: frame_part.part_variants,
        )

        expect(result).to contain_exactly(diamond_small_frame.id, diamond_large_frame.id, suspension_large_frame.id)
      end
    end

    context "with mixed INCLUDE and EXCLUDE rules" do
      before do
        # Diamond frames can have Glossy finish (INCLUDE)
        create(:part_variant_compatibility,
               product: product,
               part_variant_1: diamond_small_frame,
               part_variant_2: glossy_finish_variant,
               compatibility_type: "INCLUDE")
      end

      it "applies both INCLUDE and EXCLUDE rules to unrelated variants" do
        # But Large Diamond frames cannot have Chrome finish (EXCLUDE)
        create(:part_variant_compatibility,
               product: product,
               part_variant_1: mountain_wheel_variant,
               part_variant_2: chrome_finish_variant,
               compatibility_type: "EXCLUDE")
        # For small diamond frame, only glossy should be available (due to INCLUDE)
        small_result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [diamond_small_frame, diamond_large_frame],
          target_variants: finish_part.part_variants,
        )
        expect(small_result).to contain_exactly(glossy_finish_variant.id)
      end

      it "gives precedence to EXCLUDE rules over INCLUDE rules" do
        # Add an EXCLUDE rule that conflicts with the INCLUDE rule
        create(:part_variant_compatibility,
               product: product,
               part_variant_1: road_wheel_variant,
               part_variant_2: glossy_finish_variant,
               compatibility_type: "EXCLUDE")

        create(:part_variant_compatibility,
               product: product,
               part_variant_1: diamond_small_frame,
               part_variant_2: matte_finish_variant,
               compatibility_type: "INCLUDE")

        # Even though there's an INCLUDE rule, the EXCLUDE rule should take precedence
        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [diamond_small_frame, road_wheel_variant],
          target_variants: finish_part.part_variants,
        )

        # INCLUDE rule limits to glossy, but EXCLUDE rule removes it
        expect(result).to contain_exactly(matte_finish_variant.id)
      end
    end
    

    context "with multiple selected variants" do
      before do
        create(:part_variant_compatibility,
               product: product,
               part_variant_1: diamond_small_frame,
               part_variant_2: chrome_finish_variant,
               compatibility_type: "INCLUDE")
        create(:part_variant_compatibility,
               product: product,
               part_variant_1: diamond_small_frame,
               part_variant_2: glossy_finish_variant,
               compatibility_type: "INCLUDE")

        create(:part_variant_compatibility,
               product: product,
               part_variant_1: road_wheel_variant,
               part_variant_2: chrome_finish_variant,
               compatibility_type: "INCLUDE")
      end

      it "returns variants compatible with all selected variants" do
        # With both frame and wheel selected, only chrome should work
        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [diamond_small_frame, road_wheel_variant],
          target_variants: finish_part.part_variants,
        )

        expect(result).to contain_exactly(chrome_finish_variant.id)
      end

      it "works on permutations of selected variants" do
        create(:part_variant_compatibility,
               product: product,
               part_variant_1: road_wheel_variant,
               part_variant_2: diamond_small_frame,
               compatibility_type: "INCLUDE")

        # The order of selected variants should not matter
        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [road_wheel_variant, chrome_finish_variant],
          target_variants: frame_part.part_variants,
        )

        expect(result).to contain_exactly(diamond_small_frame.id)
      end

      it "scopes rules to parts and assumes compatibility for other parts" do

        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [diamond_small_frame],
          target_variants: [road_wheel_variant],
        )

        expect(result).to contain_exactly(road_wheel_variant.id)
      end
    end
    

    context "with compatibility using part options" do
      before do
        # Create option value compatibility rules
        # Diamond frame type is compatible with Glossy finish
        create(:part_option_compatibility,
               product: product,
               option_value_1_id: diamond_frame.id,
               option_value_2_id: glossy_finish.id,
               compatibility_type: "INCLUDE")

        # Suspension frame type is compatible with Matte finish
        create(:part_option_compatibility,
               product: product,
               option_value_1_id: suspension_frame.id,
               option_value_2_id: matte_finish.id,
               compatibility_type: "INCLUDE")
      end

      it "returns variants with compatible option values" do
        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [diamond_small_frame],
          target_variants: finish_part.part_variants,
        )

        expect(result).to contain_exactly(glossy_finish_variant.id)
      end

      it "ignores inactive compatibility rules" do
        create(:part_option_compatibility,
               product: product,
               option_value_1_id: diamond_frame.id,
               option_value_2_id: matte_finish.id,
               compatibility_type: "INCLUDE",
               active: false)

        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [diamond_small_frame],
          target_variants: finish_part.part_variants,
        )

        expect(result).to contain_exactly(glossy_finish_variant.id)
      end

      it "properly scopes compatibility rules to a product" do
        result = described_class.get_compatible_variants_ids(
          product: create(:product),
          selected_variants: [diamond_small_frame],
          target_variants: finish_part.part_variants,
        )

        expect(result).to be_empty
      end

      it "returns correct variants when called in reverse order" do
        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [glossy_finish_variant],
          target_variants: frame_part.part_variants,
        )

        expect(result).to contain_exactly(diamond_small_frame.id, diamond_large_frame.id)
      end

      it "handles option exclusion rules correctly" do
        # Add an EXCLUDE rule
        create(:part_option_compatibility,
               product: product,
               option_value_1_id: large_size.id,
               option_value_2_id: glossy_finish.id,
               compatibility_type: "EXCLUDE")

        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [diamond_large_frame],
          target_variants: finish_part.part_variants,
        )

        expect(result).to be_empty
      end

      it "handles multiple parts with option compatibility rules" do
        # Mountain wheel is compatible with glossy finish
        create(:part_option_compatibility,
               product: product,
               option_value_1_id: mountain_wheel.id,
               option_value_2_id: glossy_finish.id,
               compatibility_type: "INCLUDE")

        # This overwrites the previous rule - diamond frame now compatible with matte finish
        # However, the parent before block already established diamond frame + glossy finish
        create(:part_option_compatibility,
               product: product,
               option_value_1_id: diamond_frame.id,
               option_value_2_id: matte_finish.id,
               compatibility_type: "INCLUDE")

        # With mountain wheel and diamond frame selected, only glossy finish should be compatible
        # as it's the intersection of their compatible options
        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [mountain_wheel_variant, diamond_small_frame],
          target_variants: finish_part.part_variants,
        )

        # The expected result should ONLY include glossy_finish_variant
        expect(result).to contain_exactly(glossy_finish_variant.id)
      end
      
      it "scopes compatibility rules to parts" do
        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [diamond_small_frame],
          target_variants: [mountain_wheel_variant],
        )
        expect(result).to contain_exactly(mountain_wheel_variant.id)
      end
    end

    context "with both part variant and part option compatibility rules" do
      before do
        # Part variant compatibility: diamond_small_frame can have chrome_finish
        create(:part_variant_compatibility,
               product: product,
               part_variant_1_id: diamond_small_frame.id,
               part_variant_2_id: chrome_finish_variant.id,
               compatibility_type: "INCLUDE")

        # Option value compatibility: diamond frame type can have glossy finish
        create(:part_option_compatibility,
               product: product,
               option_value_1_id: diamond_frame.id,
               option_value_2_id: glossy_finish.id,
               compatibility_type: "INCLUDE")
      end

      it "applies both types of rules correctly" do
        # Small diamond frame should be compatible with both chrome (variant rule) and glossy (option rule)
        small_result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [diamond_small_frame],
          target_variants: finish_part.part_variants,
        )
        expect(small_result).to contain_exactly(chrome_finish_variant.id, glossy_finish_variant.id)
      end

      it "resolves conflicting rules with precedence to EXCLUDE" do
        create(:part_option_compatibility,
               product: product,
               option_value_1_id: small_size.id,
               option_value_2_id: chrome_finish.id,
               compatibility_type: "EXCLUDE")

        result = described_class.get_compatible_variants_ids(
          product: product,
          selected_variants: [diamond_large_frame],
          target_variants: finish_part.part_variants,
        )

        expect(result).to contain_exactly(glossy_finish_variant.id)
      end
    end
  end
  
  describe ".are_compatible?" do

    before do
      # Part variant compatibility: diamond_small_frame can have chrome_finish
      create(:part_variant_compatibility,
             product: product,
             part_variant_1_id: diamond_small_frame.id,
             part_variant_2_id: chrome_finish_variant.id,
             compatibility_type: "INCLUDE")

      # Option value compatibility: diamond frame type can have glossy finish
      create(:part_option_compatibility,
             product: product,
             option_value_1_id: diamond_frame.id,
             option_value_2_id: mountain_wheel.id,
             compatibility_type: "INCLUDE")
      
    end

    it "returns true if all variants are compatible" do
      selected_variants = [diamond_small_frame, chrome_finish_variant, mountain_wheel_variant]
      result = described_class.are_compatible?(
        product: product,
        variants: selected_variants,
      )

      expect(result).to be_truthy
    end
    
    it "returns false if any variant is incompatible" do
      selected_variants = [diamond_small_frame, matte_finish_variant, mountain_wheel_variant]
      result = described_class.are_compatible?(
        product: product,
        variants: selected_variants,
      )

      expect(result).to be_falsey
    end
  end
end
