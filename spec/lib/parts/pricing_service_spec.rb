require "spec_helper"
require_relative "../../support/parts_setup_context"

RSpec.describe Parts::PricingService do
  describe ".get_price_adjustments" do
    include_context "parts setup"

    let(:described_class) { Parts::PricingService.new(cache: Cache::RedisCache.new) }

    it "returns empty array when no price rules exist" do
      result = described_class.get_price_adjustments(
        product: product,
        selected_variants: [diamond_small_frame],
        target_part: finish_part,
      )

      expect(result).to be_empty
    end

    it "returns empty array when no selected variants" do
      result = described_class.get_price_adjustments(
        product: product,
        selected_variants: [],
        target_part: finish_part,
      )

      expect(result).to be_empty
    end

    context "with single price adjustment rule" do
      before do
        # Diamond frame + Matte finish costs extra $15
        create(:price_adjustment,
               product: product,
               option_value_1_id: diamond_frame.id,
               option_value_2_id: matte_finish.id,
               price_adjustment: 15.00,
               name: "Premium Matte on Diamond",
               description: "Premium matte finish on diamond frames")
      end

      it "returns price adjustment for matching option values" do
        result = described_class.get_price_adjustments(
          product: product,
          selected_variants: [diamond_small_frame],
          target_part: finish_part,
        )

        expect(result.count).to eq(1)
        price_adj = result.first
        valid_ids = [diamond_small_frame.id, matte_finish_variant.id]
        expect(price_adj).to include(
          {
            variant_1_id: be_in(valid_ids),
            variant_2_id: be_in(valid_ids),
            amount: 15.00,
            name: "Premium Matte on Diamond",
            description: "Premium matte finish on diamond frames",
          }
        )
        expect(price_adj[:variant_1_id]).not_to eq(price_adj[:variant_2_id])
      end

      it "returns relevant price adjustments when called in reverse order" do
        result = described_class.get_price_adjustments(
          product: product,
          selected_variants: [matte_finish_variant],
          target_part: frame_part,
        )

        # there should be two price adjustments: for small and large diamond frames
        valid_ids = [matte_finish_variant.id, diamond_small_frame.id, diamond_large_frame.id]
        expect(result.count).to eq(2)
        expect(result.first).to include(
          {
            variant_1_id: be_in(valid_ids),
            variant_2_id: be_in(valid_ids),
            amount: 15.00,
            name: "Premium Matte on Diamond",
            description: "Premium matte finish on diamond frames",
          }
        )
      end

      it "ignores inactive price adjustment rules" do
        create(:price_adjustment,
               product: product,
               option_value_1_id: diamond_frame.id,
               option_value_2_id: glossy_finish.id,
               price_adjustment: 15.00,
               active: false)

        result = described_class.get_price_adjustments(
          product: product,
          selected_variants: [diamond_small_frame],
          target_part: finish_part,
        )

        expect(result.count).to eq(1)
        expect(result.first[:variant_1_id]).not_to eq(glossy_finish_variant.id)
        expect(result.first[:variant_2_id]).not_to eq(glossy_finish_variant.id)
      end
      
      it "properly scopes price adjustments to a product" do
        result = described_class.get_price_adjustments(
          product: create(:product),
          selected_variants: [diamond_small_frame],
          target_part: finish_part,
        )

        expect(result).to be_empty
      end
    end

    context "with multiple price adjustment rules" do
      before do
        # Large size + Chrome finish costs extra $25
        create(:price_adjustment,
               product: product,
               option_value_1_id: large_size.id,
               option_value_2_id: chrome_finish.id,
               price_adjustment: 25.00,
               name: "Chrome on Large Frame",
               description: "Chrome finish on large frames")
      end

      it "returns different price adjustments for different variants" do
        # Diamond frame + Matte finish costs extra $15
        create(:price_adjustment,
               product: product,
               option_value_1_id: diamond_frame.id,
               option_value_2_id: matte_finish.id,
               price_adjustment: 15.00,
               name: "Premium Matte on Diamond",
               description: "Premium matte finish on diamond frames")

        # Diamond Large Frame can have both rules apply
        result = described_class.get_price_adjustments(
          product: product,
          selected_variants: [diamond_large_frame],
          target_part: finish_part,
        )

        valid_diamond_ids = [diamond_large_frame.id, matte_finish_variant.id]
        valid_chrome_ids = [diamond_large_frame.id, chrome_finish_variant.id]
        sorted_result = result.sort_by { |r| [r[:amount]] }

        expect(result.count).to eq(2)
        expect(sorted_result.first).to include(
          {
            variant_1_id: be_in(valid_diamond_ids),
            variant_2_id: be_in(valid_diamond_ids),
            amount: 15.00,
            name: "Premium Matte on Diamond",
            description: "Premium matte finish on diamond frames",
          }
        )
        expect(sorted_result.last).to include(
          {
            variant_1_id: be_in(valid_chrome_ids),
            variant_2_id: be_in(valid_chrome_ids),
            amount: 25.00,
            name: "Chrome on Large Frame",
            description: "Chrome finish on large frames",
          }
        )
      end

      it "combines multiple adjustments for the same variant pair" do
        # Create another rule for large diamond frames with chrome finish
        create(:price_adjustment,
               product: product,
               option_value_1_id: diamond_frame.id,
               option_value_2_id: chrome_finish.id,
               price_adjustment: 10.00,
               name: "Chrome on Diamond",
               description: "Chrome finish on diamond frames")

        result = described_class.get_price_adjustments(
          product: product,
          selected_variants: [diamond_large_frame],
          target_part: finish_part,
        )

        sorted_result = result.sort_by { |r| [r[:amount]] }
        valid_ids = [diamond_large_frame.id, chrome_finish_variant.id]

        expect(result.count).to eq(2)
        expect(sorted_result.first).to include(
          {
            variant_1_id: be_in(valid_ids),
            variant_2_id: be_in(valid_ids),
            amount: 10.00,
            name: "Chrome on Diamond",
            description: "Chrome finish on diamond frames",
          }
        )
        expect(sorted_result.last).to include(
          {
            variant_1_id: be_in(valid_ids),
            variant_2_id: be_in(valid_ids),
            amount: 25.00,
            name: "Chrome on Large Frame",
            description: "Chrome finish on large frames",
          }
        )
      end
    end

    context "with multiple selected variants" do
      before do
        # Diamond frame + Matte finish costs extra $15
        create(:price_adjustment,
               product: product,
               option_value_1_id: diamond_frame.id,
               option_value_2_id: matte_finish.id,
               price_adjustment: 15.00,
               name: "Premium Matte on Diamond",
               description: "Premium matte finish on diamond frames")

        # Mountain wheel + Matte finish costs extra $8
        create(:price_adjustment,
               product: product,
               option_value_1_id: mountain_wheel.id,
               option_value_2_id: matte_finish.id,
               price_adjustment: 8.00,
               name: "Matte with Mountain Wheels",
               description: "Matte finish with mountain wheels")
      end

      it "returns all applicable price adjustments based on selected variants" do
        result = described_class.get_price_adjustments(
          product: product,
          selected_variants: [diamond_small_frame, mountain_wheel_variant],
          target_part: finish_part,
        )

        valid_diamond_matte_ids = [diamond_small_frame.id, matte_finish_variant.id]
        valid_mountain_matte_ids = [mountain_wheel_variant.id, matte_finish_variant.id]
        sorted_result = result.sort_by { |r| [r[:amount]] }

        expect(result.count).to eq(2)
        expect(sorted_result.first).to include(
          {
            variant_1_id: be_in(valid_mountain_matte_ids),
            variant_2_id: be_in(valid_mountain_matte_ids),
            amount: 8.00,
            name: "Matte with Mountain Wheels",
            description: "Matte finish with mountain wheels",
          }
        )
        expect(sorted_result.last).to include(
          {
            variant_1_id: be_in(valid_diamond_matte_ids),
            variant_2_id: be_in(valid_diamond_matte_ids),
            amount: 15.00,
            name: "Premium Matte on Diamond",
            description: "Premium matte finish on diamond frames",
          }
        )
      end

      it "returns no adjustments for variants without rules" do
        result = described_class.get_price_adjustments(
          product: product,
          selected_variants: [diamond_small_frame, mountain_wheel_variant],
          target_part: finish_part,
        )

        # Check no adjustment exists for glossy finish
        result.each do |adjustment|
          expect(adjustment[:variant_2_id]).not_to eq(glossy_finish_variant.id)
        end
      end
    end

    context "when target part has no variants" do
      let(:empty_part) { create(:part, product: product, name: "Empty Part") }

      it "returns an empty array" do
        result = described_class.get_price_adjustments(
          product: product,
          selected_variants: [diamond_small_frame],
          target_part: empty_part,
        )

        expect(result).to be_empty
      end
    end
  end
end
