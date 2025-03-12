class PartOptionCompatibility < ActiveRecord::Base
  belongs_to :option_value_1, class_name: "OptionValue", foreign_key: "option_value_1_id"
  belongs_to :option_value_2, class_name: "OptionValue", foreign_key: "option_value_2_id"
  belongs_to :product

  scope :active, -> { where(active: true) }
  scope :for_product, ->(product) { where(product: product) }

  validates :compatibility_type, presence: true, inclusion: { in: %w[INCLUDE EXCLUDE] }
  validates :product, presence: true

  def self.with_variants_and_parts_ids
    select(
      "part_option_compatibilities.*,
       pv1.part_variant_id as part_variant_1_id,
       pv2.part_variant_id as part_variant_2_id,
       v1.part_id as part_1_id,
       v2.part_id as part_2_id"
    )
      .joins("JOIN part_variant_option_values pv1 ON pv1.option_value_id = option_value_1_id")
      .joins("JOIN part_variant_option_values pv2 ON pv2.option_value_id = option_value_2_id")
      .joins("JOIN part_variants v1 ON pv1.part_variant_id = v1.id")
      .joins("JOIN part_variants v2 ON pv2.part_variant_id = v2.id")
  end

  private

  def purge_cache
    Cache::RedisCache.purge(Parts::CompatibilityService::CACHE_KEY_ALL)
  end
end
