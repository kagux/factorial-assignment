require "spec_helper"

RSpec.shared_context "parts setup" do
  # Parts setup
  let(:product) { create(:product) }

  # Parts
  let(:frame_part) { create(:part, product: product, name: "Frame") }
  let(:finish_part) { create(:part, product: product, name: "Frame Finish") }
  let(:wheel_part) { create(:part, product: product, name: "Wheel") }

  # Options
  let(:frame_type_option) { create(:option, part: frame_part, name: "Type") }
  let(:frame_size_option) { create(:option, part: frame_part, name: "Size") }
  let(:finish_type_option) { create(:option, part: finish_part, name: "Type") }
  let(:wheel_type_option) { create(:option, part: wheel_part, name: "Type") }

  # Option values
  let(:diamond_frame) { create(:option_value, option: frame_type_option, value: "Diamond") }
  let(:suspension_frame) { create(:option_value, option: frame_type_option, value: "Full Suspension") }
  let(:small_size) { create(:option_value, option: frame_size_option, value: "Small") }
  let(:large_size) { create(:option_value, option: frame_size_option, value: "Large") }
  let(:matte_finish) { create(:option_value, option: finish_type_option, value: "Matte") }
  let(:glossy_finish) { create(:option_value, option: finish_type_option, value: "Glossy") }
  let(:chrome_finish) { create(:option_value, option: finish_type_option, value: "Chrome") }
  let(:mountain_wheel) { create(:option_value, option: wheel_type_option, value: "Mountain") }
  let(:road_wheel) { create(:option_value, option: wheel_type_option, value: "Road") }

  # Part variants
  let(:diamond_small_frame) { create(:part_variant, part: frame_part, name: "Diamond Small Frame", price: 100, product: product) }
    let(:diamond_large_frame) { create(:part_variant, part: frame_part, name: "Diamond Large Frame", price: 120, product: product) }
  let(:suspension_small_frame) { create(:part_variant, part: frame_part, name: "Suspension Small Frame", price: 150, product: product) }
  let(:suspension_large_frame) { create(:part_variant, part: frame_part, name: "Suspension Large Frame", price: 180, product: product) }

  let(:matte_finish_variant) { create(:part_variant, part: finish_part, name: "Matte Finish", price: 20, product: product) }
  let(:glossy_finish_variant) { create(:part_variant, part: finish_part, name: "Glossy Finish", price: 30, product: product) }
  let(:chrome_finish_variant) { create(:part_variant, part: finish_part, name: "Chrome Finish", price: 50, product: product) }

  let(:mountain_wheel_variant) { create(:part_variant, part: wheel_part, name: "Mountain Wheel", price: 80, product: product) }
  let(:road_wheel_variant) { create(:part_variant, part: wheel_part, name: "Road Wheel", price: 60, product: product) }

  # Associate option values with part variants
  before do
    # Frame variants
    create(:part_variant_option_value, part_variant: diamond_small_frame, option_value: diamond_frame)
    create(:part_variant_option_value, part_variant: diamond_small_frame, option_value: small_size)

    create(:part_variant_option_value, part_variant: diamond_large_frame, option_value: diamond_frame)
    create(:part_variant_option_value, part_variant: diamond_large_frame, option_value: large_size)

    create(:part_variant_option_value, part_variant: suspension_small_frame, option_value: suspension_frame)
    create(:part_variant_option_value, part_variant: suspension_small_frame, option_value: small_size)

    create(:part_variant_option_value, part_variant: suspension_large_frame, option_value: suspension_frame)
    create(:part_variant_option_value, part_variant: suspension_large_frame, option_value: large_size)

    # Finish variants
    create(:part_variant_option_value, part_variant: matte_finish_variant, option_value: matte_finish)
    create(:part_variant_option_value, part_variant: glossy_finish_variant, option_value: glossy_finish)
    create(:part_variant_option_value, part_variant: chrome_finish_variant, option_value: chrome_finish)

    # Wheel variants
    create(:part_variant_option_value, part_variant: mountain_wheel_variant, option_value: mountain_wheel)
    create(:part_variant_option_value, part_variant: road_wheel_variant, option_value: road_wheel)
  end
end
