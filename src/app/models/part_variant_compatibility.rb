class PartVariantCompatibility < ActiveRecord::Base
  belongs_to :part_variant_1, class_name: "PartVariant", foreign_key: "part_variant_1_id"
  belongs_to :part_variant_2, class_name: "PartVariant", foreign_key: "part_variant_2_id"
  belongs_to :product
  
  scope :active, -> { where(active: true) }
  scope :for_product, -> (product) { where(product: product) }
  
  validates :compatibility_type, presence: true, inclusion: { in: %w[INCLUDE EXCLUDE] }
  validates :product, presence: true

  after_commit :purge_cache

  private

  def purge_cache
    Cache::RedisCache.purge(Parts::CompatibilityService::CACHE_KEY_ALL)
  end
end
