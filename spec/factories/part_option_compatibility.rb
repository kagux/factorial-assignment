FactoryBot.define do
  factory :part_option_compatibility do
    association :option_value_1, factory: :option_value
    association :option_value_2, factory: :option_value
    compatibility_type { 'INCLUDE' }
    
    # Ensure option_value_1.id is less than option_value_2.id to satisfy CHECK constraint
    after(:build) do |compat|
      if compat.option_value_1_id >= compat.option_value_2_id
        temp = compat.option_value_1_id
        compat.option_value_1_id = compat.option_value_2_id
        compat.option_value_2_id = temp
      end
    end
  end
end