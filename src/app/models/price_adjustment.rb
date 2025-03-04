class PriceAdjustment < ActiveRecord::Base
  belongs_to :product
  belongs_to :option_value_1, class_name: "OptionValue", foreign_key: "option_value_1_id"
  belongs_to :option_value_2, class_name: "OptionValue", foreign_key: "option_value_2_id"
  
  scope :active, -> { where(active: true) }
  scope :for_product, -> (product) { where(product: product) }

  validates :price_adjustment, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :name, presence: true

  after_commit :purge_cache

  def self.with_variants_ids
    select("pv1.part_variant_id AS part_variant_1_id, pv2.part_variant_id AS part_variant_2_id, price_adjustments.*")
      .joins("JOIN part_variant_option_values pv1 ON pv1.option_value_id = price_adjustments.option_value_1_id")
      .joins("JOIN part_variant_option_values pv2 ON pv2.option_value_id = price_adjustments.option_value_2_id")
  end

  private

  def purge_cache
    Cache::RedisCache.purge(Parts::PricingService::CACHE_KEY_ALL)
  end
end
