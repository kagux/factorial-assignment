class OptionValue < ActiveRecord::Base
  belongs_to :option
  has_many :part_variant_option_values
  has_many :part_variants, through: :part_variant_option_values

  validates :value, presence: true
  validates :value, uniqueness: { scope: :option_id }
end
