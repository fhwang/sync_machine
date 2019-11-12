module SyncMachine
  class EnsurePublication
    # Manage logic around whether the document was previously published at all,
    # and maintaining history for future jobs.
    class PublicationHistory
      def initialize(subject_id:, sync_module:)
        @subject_id = subject_id
        @sync_module = sync_module
      end

      def last_publish_equals?(payload_body)
        return false unless previous_payload
        HashWithIndifferentAccess.new(previous_payload.body) ==
          HashWithIndifferentAccess.new(payload_body)
      end

      def last_job_finished_at
        previous_payload.try(:generated_at)
      end

      def record_generation_time
        previous_payload.update_attribute(:generated_at, Time.now)
      end

      def update(payload_body)
        if previous_payload
          previous_payload.update_attributes(
            body: payload_body, generated_at: Time.now
          )
        else
          create_payload_record(payload_body)
        end
      end

      private

      def create_payload_record(payload_body)
        payload_class.create!(
          body: payload_body,
          generated_at: Time.now,
          subject_id: @sync_module.orm_adapter.record_id_for_job(@subject_id)
        )
      end

      def payload_class
        @payload_class ||= @sync_module.const_get('Payload')
      end

      def previous_payload
        @previous_payload ||= payload_class.where(subject_id: @subject_id).first
      end
    end
  end
end
