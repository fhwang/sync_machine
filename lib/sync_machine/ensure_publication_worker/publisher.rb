module SyncMachine
  class EnsurePublicationWorker
    class Publisher
      def initialize(after_publish_hook:, payload_body:, payload_class:, previous_payload:, publish_hook:, subject:)
        @after_publish_hook = after_publish_hook
        @payload_body = payload_body
        @payload_class = payload_class
        @previous_payload = previous_payload
        @publish_hook = publish_hook
        @subject = subject
      end

      def publish
        @publish_hook.call(@subject, @payload_body)
        save_payload_body
        if @after_publish_hook
          @after_publish_hook.call(@subject)
        end
      end

      private

      def save_payload_body
        if @previous_payload
          @previous_payload.update_attributes(
            body: @payload_body, generated_at: Time.now
          )
        else
          @payload_class.create!(
            body: @payload_body,
            generated_at: Time.now,
            subject_id: @subject.id.to_s
          )
        end
      end
    end
  end
end
