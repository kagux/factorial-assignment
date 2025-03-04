class PartVariantOptionValue < ActiveRecord::Base
  belongs_to :part_variant
  belongs_to :option_value
end