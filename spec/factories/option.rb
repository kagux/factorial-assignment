FactoryBot.define do
  factory :option do
    association :part
    name { %w[color size type material style shape weight].sample }
    option_key { name&.downcase }
  end
end