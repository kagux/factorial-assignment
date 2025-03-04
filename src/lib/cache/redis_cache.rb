require "json"

module Cache
  class RedisCache
    def self.purge(key)
      $redis.del(key)
    end

    def get(key, expires: 5.minutes, &block)
      cached_data = $redis.get(key)

      return refresh(key, expires, block) if cached_data.nil?

      begin
        JSON.parse(cached_data, symbolize_names: true)
      rescue JSON::ParserError
        refresh(key, expires, block)
      end
    end

    private

    def refresh(key, expires, block)
      result = block.call
      serialized = serialize(result)
      $redis.setex(key, expires, serialized)
      result
    end

    def serialize(result)
      JSON.generate(result)
    end
  end
end
