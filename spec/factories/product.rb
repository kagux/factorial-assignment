FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    product_key { name.downcase.gsub(" ", "_") }
  end
end
