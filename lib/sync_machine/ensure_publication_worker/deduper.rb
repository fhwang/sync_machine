module SyncMachine
  class EnsurePublicationWorker
    class Deduper
      def initialize(enqueue_time_str:, previous_payload:, job_class:, subject_id:)
        @enqueue_time_str = enqueue_time_str
        @job_class = job_class
        @previous_payload = previous_payload
        @subject_id = subject_id
      end

      def dedupe(&block)
        redis_lock = "#{@job_class.name}:#{@subject_id}"
        lock_acquired = Redis.current.set(
          redis_lock, "true", nx: true, ex: 10.minutes
        )
        if lock_acquired
          begin
            if !performed_since_enqueue_time?
              block.call
            end
          ensure
            Redis.current.del(redis_lock)
          end
        else
          @job_class.perform_in(1 + rand(10), @subject_id, @enqueue_time_str)
        end
      end

      private

      def enqueue_time
        @enqueue_time ||= Time.parse(@enqueue_time_str)
      end

      def performed_since_enqueue_time?
        @previous_payload && @previous_payload.generated_at > enqueue_time
      end
    end
  end
end
