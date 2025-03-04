module Cache
  class NullCache
    def get(key, expires: 5.minutes, &block)
      block.call
    end
  end
end
