FactoryBot.define do
  factory :option_value do
    association :option
    value { [Faker::Commerce.material, Faker::Commerce.color].sample }
  end
end