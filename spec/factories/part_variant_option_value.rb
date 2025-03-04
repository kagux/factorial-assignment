FactoryBot.define do
  factory :part_variant_option_value do
    association :part_variant
    association :option_value
  end
end
