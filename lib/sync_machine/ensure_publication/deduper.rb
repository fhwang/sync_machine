module SyncMachine
  class EnsurePublication
    # Ensures that the current job is not:
    # 1. Currently being run by another worker
    # 2. Rendered unnecessary by the fact another job with the same subject was
    #    completed since the time this job was requested.
    class Deduper
      def initialize(enqueue_time_str:, last_job_finished_at:, job_class:, subject_id:)
        @enqueue_time_str = enqueue_time_str
        @job_class = job_class
        @last_job_finished_at = last_job_finished_at
        @subject_id = subject_id
      end

      def dedupe
        if acquire_lock
          begin
            yield unless performed_since_enqueue_time?
          ensure
            Redis.current.del(redis_lock)
          end
        else
          @job_class.perform_in(1 + rand(10), @subject_id, @enqueue_time_str)
        end
      end

      private

      def acquire_lock
        Redis.current.set(redis_lock, "true", nx: true, ex: 10.minutes)
      end

      def enqueue_time
        @enqueue_time ||= Time.parse(@enqueue_time_str)
      end

      def performed_since_enqueue_time?
        @last_job_finished_at && @last_job_finished_at > enqueue_time
      end

      def redis_lock
        "#{@job_class.name}:#{@subject_id}"
      end
    end
  end
end
