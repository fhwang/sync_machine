require "active_support/core_ext/class"
require "sidekiq"

module SyncMachine
  class EnsurePublicationWorker
    include Sidekiq::Worker

    class_attribute :hooks

    [:build, :check_publishable, :publish, :after_publish].each do |hook|
      define_singleton_method(hook) do |&block|
        self.hooks[hook] = block
      end
    end

    def self.inherited(subclass)
      subclass.hooks = {}
    end

    def perform(subject_id, enqueue_time_str)
      @subject_id = subject_id
      @enqueue_time_str = enqueue_time_str
      deduper = Deduper.new(
        job_class: self.class,
        previous_payload: previous_payload,
        subject_id: subject_id,
        enqueue_time_str: enqueue_time_str
      )
      deduper.dedupe do
        if self.class.hooks[:check_publishable].call(subject)
          payload_body = self.class.hooks[:build].call(subject)
          if same_payload_body?(payload_body)
            previous_payload.update_attribute(:generated_at, Time.now)
          else
            publisher = Publisher.new(
              after_publish_hook: self.class.hooks[:after_publish],
              payload_body: payload_body,
              payload_class: payload_class,
              previous_payload: previous_payload,
              publish_hook: self.class.hooks[:publish],
              subject: subject
            )
            publisher.publish
          end
        end
      end
    end

    private

    def enqueue_time
      @enqueue_time ||= Time.parse(@enqueue_time_str)
    end

    def payload_class
      @payload_class ||= self.class.parent.const_get('Payload')
    end

    def previous_payload
      unless @previous_payload
        @previous_payload = payload_class.where(subject_id: @subject_id).first
      end
      @previous_payload
    end

    def same_payload_body?(payload_body)
      if previous_payload
        HashWithIndifferentAccess.new(previous_payload.body) ==
          HashWithIndifferentAccess.new(payload_body)
      end
    end

    def subject
      unless @subject
        sync_module = self.class.name.split(/::/).first.constantize
        subject_class = sync_module.subject_class
        @subject = subject_class.find(@subject_id)
      end
      @subject
    end
  end
end
