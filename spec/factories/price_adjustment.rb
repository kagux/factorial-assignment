FactoryBot.define do
  factory :price_adjustment do
    association :option_value_1, factory: :option_value
    association :option_value_2, factory: :option_value
    price_adjustment { Faker::Commerce.price(range: 5..50.0) }
    name { "#{Faker::Commerce.material} Premium" }
    description { Faker::Lorem.sentence }

    # Ensure option_value_1_id is less than option_value_2_id to satisfy CHECK constraint
    after(:build) do |adjust|
      if adjust.option_value_1_id >= adjust.option_value_2_id
        temp = adjust.option_value_1
        adjust.option_value_1 = adjust.option_value_2
        adjust.option_value_2 = temp
      end
    end
  end
end
