module Parts
  # The PricingService class handles price adjustment calculations between part variants.
  # It uses caching to store and retrieve price adjustment rules efficiently.
  #
  # @example Get price adjustments for target part based on selected variants for a product
  #   service = PricingService.new
  #   adjustments = service.get_price_adjustments(
  #     product: product,
  #     selected_variants: [variant1, variant2],
  #     target_part: target_part
  #   )
  #
  # Price adjustments are stored in an indexed format for quick lookups:
  # - by_pair: Maps pairs of variant IDs to sets of rule IDs
  # - by_variants: Maps individual variant IDs to sets of related variant IDs
  # - by_id: Maps rule IDs to rule details
  #
  # Cache Memory usage estimation for 1000 variants and 100 rules
  # Assuming only 30% of pairs have a matching rule
  # - by_variants: 1000 entries * 50 ids * ~36 bytes per UUID = ~1.8MB
  # - by_pair: (1000 * 0.3) * (1000 * 0.3 - 1)/2 pairs * 1 rule * ~36 bytes = ~1.6MB
  # - by_id: Assuming ~400 bytes per rule:
  #   - amount (decimal): ~8 bytes
  #   - name (string): ~100 bytes average
  #   - description (string): ~250 bytes average
  #   - hash overhead: ~40 bytes
  #   Total by_id: ~400KB for 1000 rules
  #
  # Total estimated cache size: ~3.8MB

  # @attr_reader [Cache] cache The caching mechanism used to store price adjustment rules
  # @attr_reader [Integer] batch_size The number of records to process at once when indexing rules
  class PricingService
    CACHE_KEY_SINGLE = "factorial:price_adjustments:product:"
    CACHE_KEY_ALL = "factorial:price_adjustments:*"

    def initialize(cache: Cache::RedisCache.new, batch_size: 200)
      @cache = cache
      @batch_size = batch_size
    end

    # Determines price adjustments for variants of a target part based on already selected variants
    # @param product: The product we want to find price adjustments for
    # @param selected_variants: Array of currently selected variants
    # @param target_variants: Array of target variants we want to find price adjustments for
    # @return Array of price adjustment objects with variant_1_id, variant_2_id, and adjustment details
    def get_price_adjustments(product:, selected_variants:, target_variants:)

      return [] if selected_variants.empty?

      selected_variants_ids = selected_variants.pluck(:id)
      target_variants_ids = Set.new target_variants.pluck(:id)
      rules = rules_for_product(product)
      seen_pairs = Set.new
      price_adjustments = []

      selected_variants_ids.each do |id|
        matching_ids = rules[:by_variants][id] & target_variants_ids
        matching_ids.each do |match_id|
          pair_id = variants_pair_id(id, match_id)
          next if seen_pairs.include?(pair_id)
          
          seen_pairs << pair_id
          matching_rules = get_matching_rules_from_index(rules, id, match_id)
          price_adjustments.concat(matching_rules)
        end
      end
      price_adjustments
    end

    private

    def get_matching_rules_from_index(rules, variant_1_id, variant_2_id)
      pair_id = variants_pair_id(variant_1_id, variant_2_id)
      
      rules[:by_pair][pair_id].map do |rule_id|
        rules[:by_id][rule_id].merge(
          variant_1_id: variant_1_id < variant_2_id ? variant_1_id : variant_2_id,
          variant_2_id: variant_1_id < variant_2_id ? variant_2_id : variant_1_id,
        )
      end
    end

    def rules_for_product(product)
      cache_key = CACHE_KEY_SINGLE + product.id
      @rules ||= @cache.get(cache_key) do
        index_rules_for_product(product)
      end
    end

    def index_rules_for_product(product)
      hash_set = Hash.new { |h, k| h[k] = Set.new }
      rules = { by_pair: hash_set, by_variants: hash_set, by_id: {} }

      raw_rules_for_product(product).find_each(batch_size: @batch_size) do |rule|
        key_1 = rule.part_variant_1_id
        key_2 = rule.part_variant_2_id
        pair_id = variants_pair_id(key_1, key_2)
        rules[:by_pair][pair_id] << rule.id
        rules[:by_variants][key_1] << key_2
        rules[:by_variants][key_2] << key_1
        rules[:by_id][rule.id] = format_rule(rule)
      end

      rules
    end

    def variants_pair_id(variant_1_id, variant_2_id)
      [variant_1_id, variant_2_id].sort.join("-")
    end

    def raw_rules_for_product(product)
      PriceAdjustment.active.for_product(product).with_variants_ids
    end

    def format_rule(rule)
      {
        id: rule.id,
        amount: rule.price_adjustment,
        name: rule.name,
        description: rule.description,
      }
    end
  end
end
