class PartVariantCompatibility < ActiveRecord::Base
  belongs_to :part_variant_1, class_name: "PartVariant", foreign_key: "part_variant_1_id"
  belongs_to :part_variant_2, class_name: "PartVariant", foreign_key: "part_variant_2_id"
  belongs_to :product

  scope :active, -> { where(active: true) }
  scope :for_product, ->(product) { where(product: product) }

  validates :compatibility_type, presence: true, inclusion: { in: %w[INCLUDE EXCLUDE] }
  validates :product, presence: true

  after_commit :purge_cache

  def self.with_part_ids
    select("part_variant_compatibilities.*, pv1.part_id as part_1_id, pv2.part_id as part_2_id")
      .joins("JOIN part_variants pv1 ON part_variant_1_id = pv1.id")
      .joins("JOIN part_variants pv2 ON part_variant_2_id = pv2.id")
  end

  private

  def purge_cache
    Cache::RedisCache.purge(Parts::CompatibilityService::CACHE_KEY_ALL)
  end
end
