class PartVariant < ActiveRecord::Base
  belongs_to :part
  belongs_to :product
  has_many :part_variant_option_values
  has_many :option_values, through: :part_variant_option_values
  has_many :product_build_parts
  has_many :product_builds, through: :product_build_parts

  validates :name, :price, :sku, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :sku, uniqueness: true
end
