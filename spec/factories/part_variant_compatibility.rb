FactoryBot.define do
  factory :part_variant_compatibility do
    association :part_variant_1, factory: :part_variant
    association :part_variant_2, factory: :part_variant
    compatibility_type { 'INCLUDE' }


    # Ensure part_variant_1.id is less than part_variant_2.id to satisfy CHECK constraint
    after(:build) do |compat|
      if compat.part_variant_1.id >= compat.part_variant_2.id
        temp = compat.part_variant_1
        compat.part_variant_1 = compat.part_variant_2
        compat.part_variant_2 = temp
      end
    end
  end
end