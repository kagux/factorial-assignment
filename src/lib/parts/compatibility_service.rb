# Manages compatibility rules between different part variants in a system.
#
# This service class handles the logic for determining which variants of parts
# are compatible with each other based on pre-defined rules stored in the database.
# It uses a caching mechanism to improve performance and processes rules in batches.
#
# @example
#   service = Parts::CompatibilityService.new
#   compatible_ids = service.get_compatible_variants_ids(
#     product: product,
#     selected_variants: current_variants,
#     target_part: part
#   )
# Compatibility rules are stored in an indexed format for quick lookups:
# - variant_id: Maps to a hash containing :include and :exclude Sets of compatible/incompatible variant IDs
#
# Cache Memory usage estimation for 1000 variants:
# - Indexed rules: ~1000 entries * ~8KB per entry = ~8MB
#   Breakdown per variant entry:
#   - variant_id (UUID string): ~36 bytes
#   - include Set: ~4KB (avg 100 variant IDs * 36 bytes each + Set overhead)
#   - exclude Set: ~4KB (avg 100 variant IDs * 36 bytes each + Set overhead)
#   - hash overhead: ~20 bytes
#
# Total estimated cache size: ~8MB
#
# @attr_reader [Cache] cache The caching mechanism used to store compatibility rules
# @attr_reader [Integer] batch_size The number of records to process at once when indexing rules
module Parts
  class CompatibilityService
    CACHE_KEY_SINGLE = "factorial:compatibility:product:"
    CACHE_KEY_ALL = "factorial:compatibility:*"


    def initialize(cache: Cache::RedisCache.new, batch_size: 200)
      @cache = cache
      @batch_size = batch_size
    end

    # Determines which variants of a target part are compatible with already selected variants
    # @param product: The product we want to find compatible variants for
    # @param selected_variants: Array of currently selected variants
    # @param target_part: The part we want to find compatible variants for
    # @return Array of compatible variant IDs
    def get_compatible_variants_ids(product:, selected_variants:, target_part:)
      target_variants = target_part.part_variants
      target_variants_ids = target_variants.pluck(:id)


      # if we call with a mismatching product, there will be no rules and it will appear compatible with everything
      # so either we never call this method with a mismatching product, or we double check here
      return [] if product_mismatch?(product, target_part, selected_variants)
      
      return target_variants_ids if selected_variants.empty?

      selected_variants_ids = selected_variants.pluck(:id)

      selected_variants_includes = Set.new target_variants_ids
      selected_variants_excludes = Set.new

      selected_variants_ids.each do |id|
        rule = rules_for_product(product)[id] || {}
        include_ids = rule[:include] || Set.new
        selected_variants_includes &= include_ids unless include_ids.empty?
        selected_variants_excludes += rule[:exclude] || Set.new
      end

      # Calculate final compatible IDs:
      # - Must be in target variants
      # - Must satisfy all include rules
      # - Must not be in any exclude rules
      compatible_ids = Set.new(target_variants_ids) & selected_variants_includes - selected_variants_excludes

      compatible_ids.to_a
    end

    private

    def rules_for_product(product)
      cache_key = CACHE_KEY_SINGLE + product.id
      @rules ||= @cache.get(cache_key, expires: 5.minutes) do
        index_rules_for_product(product)
      end
    end

    def index_rules_for_product(product)
      rules = Hash.new { |h, k| h[k] = { include: Set.new, exclude: Set.new } }

      add_rules_to_index(PartVariantCompatibility.active.for_product(product).all, rules)
      add_rules_to_index(PartOptionCompatibility.active.for_product(product).with_variants_ids, rules)

      rules
    end

    def add_rules_to_index(collection, rules)
      collection.find_each(batch_size: @batch_size) do |rule|
        rule_type = compatibility_type_key(rule)
        rules[rule.part_variant_1_id][rule_type] << rule.part_variant_2_id
        rules[rule.part_variant_2_id][rule_type] << rule.part_variant_1_id
      end
    end

    def compatibility_type_key(rule)
      rule.compatibility_type.downcase == "exclude" ? :exclude : :include
    end

    def product_mismatch?(product, target_part, selected_variants)
      product.id != target_part.product_id || selected_variants.any? { |v| v.product_id != product.id }
    end
  end
end
