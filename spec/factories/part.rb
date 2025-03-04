FactoryBot.define do
  factory :part do
    association :product
    name { Faker::Commerce.material }
    part_key { "#{name.downcase.gsub(" ", "_")}_#{SecureRandom.hex(4)}" }
  end
end
