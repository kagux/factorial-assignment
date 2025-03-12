require "active_record"
require "active_support"
require "active_support/core_ext/string"
require "faker"
require "logger"
require "securerandom"

# Database configuration
ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(
  adapter: "postgresql",
  host: ENV.fetch("POSTGRESQL_HOST", "localhost"),
  username: "postgres",
  password: "postgres",
  database: "factorial_development",
)

# Define models to match database schema
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Product < ApplicationRecord
  has_many :parts
end

class Part < ApplicationRecord
  belongs_to :product
  has_many :options
  has_many :part_variants
end

class Option < ApplicationRecord
  belongs_to :part
  has_many :option_values
end

class OptionValue < ApplicationRecord
  belongs_to :option
  has_many :part_variant_option_values
  has_many :part_variants, through: :part_variant_option_values
end

class PartVariant < ApplicationRecord
  belongs_to :part
  belongs_to :product
  has_many :part_variant_option_values
  has_many :option_values, through: :part_variant_option_values
end

class PartVariantOptionValue < ApplicationRecord
  belongs_to :part_variant
  belongs_to :option_value
end

class PartVariantCompatibility < ApplicationRecord
  belongs_to :product
  belongs_to :part_variant_1, class_name: "PartVariant"
  belongs_to :part_variant_2, class_name: "PartVariant"
end

class PartOptionCompatibility < ApplicationRecord
  belongs_to :product
  belongs_to :option_value_1, class_name: "OptionValue"
  belongs_to :option_value_2, class_name: "OptionValue"
end

class PriceAdjustment < ApplicationRecord
  belongs_to :product
  belongs_to :option_value_1, class_name: "OptionValue"
  belongs_to :option_value_2, class_name: "OptionValue"
end

class Customer < ApplicationRecord
  has_many :product_builds
  has_many :orders
end

class ProductBuild < ApplicationRecord
  belongs_to :product
  belongs_to :customer, optional: true
  has_many :product_build_parts, foreign_key: "build_id"
  has_many :part_variants, through: :product_build_parts
end

class ProductBuildPart < ApplicationRecord
  self.table_name = "product_build_parts"
  belongs_to :build, class_name: "ProductBuild", foreign_key: "build_id"
  belongs_to :part_variant
end

class Order < ApplicationRecord
  belongs_to :customer, optional: true
  has_many :order_product_builds
end

class OrderProductBuild < ApplicationRecord
  belongs_to :order
  belongs_to :build, class_name: "ProductBuild", optional: true
  belongs_to :product, optional: true
  has_many :order_product_build_parts
end

class OrderProductBuildPart < ApplicationRecord
  belongs_to :order_product_build
  belongs_to :part_variant, optional: true
end

# Clean up existing data
puts "Cleaning up existing data..."
OrderProductBuildPart.delete_all
OrderProductBuild.delete_all
Order.delete_all
ProductBuildPart.delete_all
ProductBuild.delete_all
PriceAdjustment.delete_all
PartOptionCompatibility.delete_all
PartVariantCompatibility.delete_all
PartVariantOptionValue.delete_all
PartVariant.delete_all
OptionValue.delete_all
Option.delete_all
Part.delete_all
Product.delete_all
Customer.delete_all

puts "Creating bicycle product..."
# Create Bicycle product
bicycle = Product.create!(
  name: "Custom Bicycle",
  product_key: "bicycle",
  description: "Build your dream bicycle with our custom parts",
  active: true,
  display_order: 1,
)

# Create parts for bicycle
puts "Creating bicycle parts..."
frame_part = Part.create!(
  product_id: bicycle.id,
  part_key: "frame",
  name: "Bicycle Frame",
  description: "The main structure of the bicycle",
  display_order: 1,
)

wheels_part = Part.create!(
  product_id: bicycle.id,
  part_key: "wheels",
  name: "Wheels",
  description: "The wheels of the bicycle",
  display_order: 2,
)

chain_part = Part.create!(
  product_id: bicycle.id,
  part_key: "chain",
  name: "Chain",
  description: "Transfers power from pedals to wheel",
  display_order: 3,
)

handlebar_part = Part.create!(
  product_id: bicycle.id,
  part_key: "handlebar",
  name: "Handlebar",
  description: "For steering and control",
  display_order: 4,
)

finish_part = Part.create!(
  product_id: bicycle.id,
  part_key: "finish",
  name: "Frame Finish",
  description: "The finish/paint of the frame",
  display_order: 5,
)

# Create options and values for frame
puts "Creating options and values for frame..."
frame_type_option = Option.create!(
  part_id: frame_part.id,
  option_key: "type",
  name: "Frame Type",
  display_order: 1,
)

frame_size_option = Option.create!(
  part_id: frame_part.id,
  option_key: "size",
  name: "Frame Size",
  display_order: 2,
)

# Frame type values
diamond_frame = OptionValue.create!(option_id: frame_type_option.id, value: "Diamond", display_order: 1)
step_through_frame = OptionValue.create!(option_id: frame_type_option.id, value: "Step-through", display_order: 2)
full_suspension_frame = OptionValue.create!(option_id: frame_type_option.id, value: "Full Suspension", display_order: 3)
hardtail_frame = OptionValue.create!(option_id: frame_type_option.id, value: "Hardtail", display_order: 4)

# Frame size values
small_frame = OptionValue.create!(option_id: frame_size_option.id, value: "Small", display_order: 1)
medium_frame = OptionValue.create!(option_id: frame_size_option.id, value: "Medium", display_order: 2)
large_frame = OptionValue.create!(option_id: frame_size_option.id, value: "Large", display_order: 3)

# Create options and values for wheels
puts "Creating options and values for wheels..."
wheel_size_option = Option.create!(
  part_id: wheels_part.id,
  option_key: "size",
  name: "Wheel Size",
  display_order: 1,
)

wheel_type_option = Option.create!(
  part_id: wheels_part.id,
  option_key: "type",
  name: "Wheel Type",
  display_order: 2,
)

rim_color_option = Option.create!(
  part_id: wheels_part.id,
  option_key: "rim_color",
  name: "Rim Color",
  display_order: 3,
)

# Wheel size values
wheel_size_26 = OptionValue.create!(option_id: wheel_size_option.id, value: "26\"", display_order: 1)
wheel_size_27 = OptionValue.create!(option_id: wheel_size_option.id, value: "27.5\"", display_order: 2)
wheel_size_29 = OptionValue.create!(option_id: wheel_size_option.id, value: "29\"", display_order: 3)

# Wheel type values
road_wheel = OptionValue.create!(option_id: wheel_type_option.id, value: "Road", display_order: 1)
mountain_wheel = OptionValue.create!(option_id: wheel_type_option.id, value: "Mountain", display_order: 2)
gravel_wheel = OptionValue.create!(option_id: wheel_type_option.id, value: "Gravel", display_order: 3)

# Rim color values
black_rim = OptionValue.create!(option_id: rim_color_option.id, value: "Black", display_order: 1)
silver_rim = OptionValue.create!(option_id: rim_color_option.id, value: "Silver", display_order: 2)
blue_rim = OptionValue.create!(option_id: rim_color_option.id, value: "Blue", display_order: 3)

# Create options and values for chain
puts "Creating options and values for chain..."
chain_speed_option = Option.create!(
  part_id: chain_part.id,
  option_key: "speed",
  name: "Chain Speed",
  display_order: 1,
)

chain_material_option = Option.create!(
  part_id: chain_part.id,
  option_key: "material",
  name: "Chain Material",
  display_order: 2,
)

# Chain speed values
speed_8 = OptionValue.create!(option_id: chain_speed_option.id, value: "8-speed", display_order: 1)
speed_10 = OptionValue.create!(option_id: chain_speed_option.id, value: "10-speed", display_order: 2)
speed_12 = OptionValue.create!(option_id: chain_speed_option.id, value: "12-speed", display_order: 3)

# Chain material values
steel_chain = OptionValue.create!(option_id: chain_material_option.id, value: "Steel", display_order: 1)
nickel_chain = OptionValue.create!(option_id: chain_material_option.id, value: "Nickel", display_order: 2)
titanium_chain = OptionValue.create!(option_id: chain_material_option.id, value: "Titanium", display_order: 3)

# Create options and values for handlebar
puts "Creating options and values for handlebar..."
handlebar_type_option = Option.create!(
  part_id: handlebar_part.id,
  option_key: "type",
  name: "Handlebar Type",
  display_order: 1,
)

handlebar_material_option = Option.create!(
  part_id: handlebar_part.id,
  option_key: "material",
  name: "Handlebar Material",
  display_order: 2,
)

# Handlebar type values
flat_handlebar = OptionValue.create!(option_id: handlebar_type_option.id, value: "Flat", display_order: 1)
drop_handlebar = OptionValue.create!(option_id: handlebar_type_option.id, value: "Drop", display_order: 2)
riser_handlebar = OptionValue.create!(option_id: handlebar_type_option.id, value: "Riser", display_order: 3)

# Handlebar material values
aluminum_handlebar = OptionValue.create!(option_id: handlebar_material_option.id, value: "Aluminum", display_order: 1)
carbon_handlebar = OptionValue.create!(option_id: handlebar_material_option.id, value: "Carbon", display_order: 2)
steel_handlebar = OptionValue.create!(option_id: handlebar_material_option.id, value: "Steel", display_order: 3)

# Create options and values for frame finish
puts "Creating options and values for frame finish..."
finish_type_option = Option.create!(
  part_id: finish_part.id,
  option_key: "type",
  name: "Finish Type",
  display_order: 1,
)

finish_color_option = Option.create!(
  part_id: finish_part.id,
  option_key: "color",
  name: "Finish Color",
  display_order: 2,
)

# Finish type values
matte_finish = OptionValue.create!(option_id: finish_type_option.id, value: "Matte", display_order: 1)
gloss_finish = OptionValue.create!(option_id: finish_type_option.id, value: "Gloss", display_order: 2)

# Finish color values
red_finish = OptionValue.create!(option_id: finish_color_option.id, value: "Red", display_order: 1)
blue_finish = OptionValue.create!(option_id: finish_color_option.id, value: "Blue", display_order: 2)
green_finish = OptionValue.create!(option_id: finish_color_option.id, value: "Green", display_order: 3)
black_finish = OptionValue.create!(option_id: finish_color_option.id, value: "Black", display_order: 4)

# Create part variants
puts "Creating part variants..."

# Helper method to generate variants
def create_variants_for_part(part, product, option_values_by_option_key, base_price, sku_prefix)
  variants = []

  # Get all possible combinations of option values
  combinations = option_values_by_option_key.values.first.product(*option_values_by_option_key.values[1..-1])

  combinations.each_with_index do |combo, index|
    # Flatten if it's nested arrays
    combo = [combo] unless combo.is_a?(Array)

    # Create a name from all option values
    variant_name_parts = []
    option_values = []

    option_values_by_option_key.keys.each_with_index do |option_key, i|
      option_value = i < combo.length ? combo[i] : combo
      variant_name_parts << option_value.value
      option_values << option_value
    end

    # Create variant name and SKU
    variant_name = "#{variant_name_parts.join(" ")} #{part.name}"
    sku = "#{sku_prefix}-#{index + 1}"

    # Create the variant with slight price variation
    price_variation = (rand * 50).round(2)
    variant = PartVariant.create!(
      part_id: part.id,
      product_id: product.id,
      name: variant_name,
      description: "#{variant_name} with premium quality.",
      price: base_price + price_variation,
      in_stock: [true, true, true, false].sample, # 75% chance of being in stock
      active: true,
      sku: sku,
    )

    # Associate option values with the variant
    option_values.each do |option_value|
      PartVariantOptionValue.create!(
        part_variant_id: variant.id,
        option_value_id: option_value.id,
      )
    end

    variants << variant
  end

  variants
end

# Create frame variants
frame_option_values = {
  "type" => [diamond_frame, step_through_frame, full_suspension_frame, hardtail_frame],
  "size" => [small_frame, medium_frame, large_frame],
}
frame_variants = create_variants_for_part(frame_part, bicycle, frame_option_values, 300.00, "FR")

# Create wheel variants
wheels_option_values = {
  "size" => [wheel_size_26, wheel_size_27, wheel_size_29],
  "type" => [road_wheel, mountain_wheel, gravel_wheel],
  "rim_color" => [black_rim, silver_rim, blue_rim],
}
wheel_variants = create_variants_for_part(wheels_part, bicycle, wheels_option_values, 150.00, "WH")

# Create chain variants
chain_option_values = {
  "speed" => [speed_8, speed_10, speed_12],
  "material" => [steel_chain, nickel_chain, titanium_chain],
}
chain_variants = create_variants_for_part(chain_part, bicycle, chain_option_values, 30.00, "CH")

# Create handlebar variants
handlebar_option_values = {
  "type" => [flat_handlebar, drop_handlebar, riser_handlebar],
  "material" => [aluminum_handlebar, carbon_handlebar, steel_handlebar],
}
handlebar_variants = create_variants_for_part(handlebar_part, bicycle, handlebar_option_values, 50.00, "HB")

# Create finish variants
finish_option_values = {
  "type" => [matte_finish, gloss_finish],
  "color" => [red_finish, blue_finish, green_finish, black_finish],
}
finish_variants = create_variants_for_part(finish_part, bicycle, finish_option_values, 20.00, "FN")

# Create compatibility rules
puts "Creating compatibility rules..."

# Option value compatibility rules
# Mountain wheels are compatible with full suspension frames
PartOptionCompatibility.create!(
  product_id: bicycle.id,
  option_value_1_id: [mountain_wheel.id, full_suspension_frame.id].min,
  option_value_2_id: [mountain_wheel.id, full_suspension_frame.id].max,
  compatibility_type: "INCLUDE",
  active: true,
)

# Road wheels are compatible with diamond frames
PartOptionCompatibility.create!(
  product_id: bicycle.id,
  option_value_1_id: [road_wheel.id, diamond_frame.id].min,
  option_value_2_id: [road_wheel.id, diamond_frame.id].max,
  compatibility_type: "INCLUDE",
  active: true,
)

# Gravel wheels are compatible with hardtail frames
PartOptionCompatibility.create!(
  product_id: bicycle.id,
  option_value_1_id: [gravel_wheel.id, hardtail_frame.id].min,
  option_value_2_id: [gravel_wheel.id, hardtail_frame.id].max,
  compatibility_type: "INCLUDE",
  active: true,
)

# 10-speed chains are compatible with mountain wheels
PartOptionCompatibility.create!(
  product_id: bicycle.id,
  option_value_1_id: [speed_10.id, mountain_wheel.id].min,
  option_value_2_id: [speed_10.id, mountain_wheel.id].max,
  compatibility_type: "INCLUDE",
  active: true,
)

# 8-speed chains are incompatible with titanium handlebar
PartOptionCompatibility.create!(
  product_id: bicycle.id,
  option_value_1_id: [speed_8.id, titanium_chain.id].min,
  option_value_2_id: [speed_8.id, titanium_chain.id].max,
  compatibility_type: "EXCLUDE",
  active: true,
)

# Create price adjustment rules
puts "Creating price adjustment rules..."

# Matte finish costs extra on Diamond frame
PriceAdjustment.create!(
  product_id: bicycle.id,
  option_value_1_id: [matte_finish.id, diamond_frame.id].min,
  option_value_2_id: [matte_finish.id, diamond_frame.id].max,
  price_adjustment: 15.00,
  name: "Premium Matte on Diamond",
  description: "Premium matte finish on diamond frames",
  active: true,
)

# Carbon handlebars cost extra with Full Suspension frames
PriceAdjustment.create!(
  product_id: bicycle.id,
  option_value_1_id: [carbon_handlebar.id, full_suspension_frame.id].min,
  option_value_2_id: [carbon_handlebar.id, full_suspension_frame.id].max,
  price_adjustment: 25.00,
  name: "Carbon Handlebar on Full Suspension",
  description: "Premium carbon handlebar installation on full suspension frames",
  active: true,
)

# Titanium chains cost extra with 12-speed
PriceAdjustment.create!(
  product_id: bicycle.id,
  option_value_1_id: [titanium_chain.id, speed_12.id].min,
  option_value_2_id: [titanium_chain.id, speed_12.id].max,
  price_adjustment: 10.00,
  name: "Titanium 12-Speed Premium",
  description: "Premium for titanium 12-speed chains",
  active: true,
)

# Create customers
puts "Creating customers..."
customers = []
5.times do
  customers << Customer.create!(
    email: Faker::Internet.unique.email,
    name: Faker::Name.name,
  )
end

# Create sample builds
puts "Creating sample builds..."
builds = []

def random_variant_for_part(part_variants, part_id)
  part_variants.select { |v| v.part_id == part_id }.sample
end

10.times do |i|
  customer = i < 5 ? customers[i] : nil  # First 5 builds have customers, others are guest builds

  build = ProductBuild.create!(
    product_id: bicycle.id,
    customer_id: customer&.id,
    name: "#{Faker::Adjective.positive} Bicycle Build #{i + 1}",
    is_completed: [true, true, true, false].sample, # 75% chance of being completed
    is_featured: i < 3, # First 3 builds are featured
  )

  # Add parts to build if completed
  if build.is_completed
    frame_variant = random_variant_for_part(frame_variants, frame_part.id)
    wheel_variant = random_variant_for_part(wheel_variants, wheels_part.id)
    chain_variant = random_variant_for_part(chain_variants, chain_part.id)
    handlebar_variant = random_variant_for_part(handlebar_variants, handlebar_part.id)
    finish_variant = random_variant_for_part(finish_variants, finish_part.id)

    [frame_variant, wheel_variant, chain_variant, handlebar_variant, finish_variant].each do |variant|
      if variant
        # Use explicit SQL to avoid ActiveRecord's assumptions about column names
        ActiveRecord::Base.connection.execute(
          "INSERT INTO product_build_parts (build_id, part_variant_id) VALUES ('#{build.id}', '#{variant.id}')"
        )
      end
    end
  end

  builds << build
end

# Create orders
puts "Creating orders..."
customers.each do |customer|
  # Each customer gets 1-3 orders
  rand(1..3).times do
    order_number = "ORD-#{SecureRandom.hex(4).upcase}"

    order = Order.create!(
      customer_id: customer.id,
      order_number: order_number,
      status: ["pending", "processing", "shipped", "delivered"].sample,
      total_amount: 0, # Will be calculated based on builds
      shipping_address: Faker::Address.full_address,
      customer_comments: Faker::Lorem.sentence,
      payment_method: ["credit_card", "paypal", "bank_transfer"].sample,
      payment_status: ["pending", "paid"].sample,
      shop_comments: Faker::Lorem.sentence,
    )

    # Add 1-2 builds to each order
    customer_builds = builds.select { |b| b.customer_id == customer.id && b.is_completed }

    selected_builds = customer_builds.sample(rand(1..2))
    total_price = 0

    selected_builds.each do |build|
      quantity = rand(1..2)

      # Calculate unit price based on parts
      unit_price = build.part_variants.sum(&:price)

      # Create order product build
      order_build = OrderProductBuild.create!(
        order_id: order.id,
        build_id: build.id,
        build_name: build.name,
        product_id: build.product_id,
        product_name: bicycle.name,
        quantity: quantity,
        unit_price: unit_price,
        total_price: unit_price * quantity,
      )

      total_price += unit_price * quantity

      # Create order product build parts
      build.part_variants.each do |variant|
        options_json = {}
        variant.option_values.each do |ov|
          option_key = ov.option.option_key
          options_json[option_key] = ov.value
        end

        OrderProductBuildPart.create!(
          order_product_build_id: order_build.id,
          part_variant_id: variant.id,
          part_variant_name: variant.name,
          part_variant_sku: variant.sku,
          price: variant.price,
          variant_options: options_json.to_json,
        )
      end
    end

    # Update order total
    order.update!(total_amount: total_price)
  end
end

puts "Seed data created successfully!"
