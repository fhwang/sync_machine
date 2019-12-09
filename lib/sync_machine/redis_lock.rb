module SyncMachine
  # General-purpose class for locking via Redis.
  class RedisLock
    def initialize(redis_key)
      @redis_key = redis_key
      @acquired = false
    end

    def acquire(&block)
      yield_and_release(block) if set_redis_key
    end

    def acquired?
      @acquired
    end

    private

    def set_redis_key
      @acquired = Redis.current.set(
        @redis_key, "true", nx: true, ex: 10.minutes
      )
    end

    def yield_and_release(block)
      block.call
    ensure
      Redis.current.del(@redis_key)
    end
  end
end
