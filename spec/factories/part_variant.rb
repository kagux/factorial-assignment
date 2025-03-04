FactoryBot.define do
  factory :part_variant do
    association :part
    name { Faker::Commerce.product_name }
    price { Faker::Commerce.price(range: 50..500.0) }
    sequence(:sku) { |n| "SKU#{n}-#{SecureRandom.hex(4)}" }
  end
end