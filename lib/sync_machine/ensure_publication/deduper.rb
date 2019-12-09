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
        lock = RedisLock.new("#{@job_class.name}:#{@subject_id}")
        lock.acquire do
          yield unless performed_since_enqueue_time?
        end
        lock.acquired? || reschedule_job
      end

      private

      def enqueue_time
        @enqueue_time ||= Time.parse(@enqueue_time_str)
      end

      def performed_since_enqueue_time?
        @last_job_finished_at && @last_job_finished_at > enqueue_time
      end

      def reschedule_job
        @job_class.perform_in(1 + rand(10), @subject_id, @enqueue_time_str)
      end
    end
  end
end
