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
      define_method(hook) do |*args|
        self.class.hooks[hook].call(*args)
      end
    end

    def self.inherited(subclass)
      subclass.hooks = {}
    end

    def perform(subject_id, enqueue_time_str)
      @subject_id = subject_id
      @enqueue_time_str = enqueue_time_str
      dedupe do
        if check_publishable(subject)
          payload_body = build(subject)
          if same_payload_body?(payload_body)
            previous_payload.update_attribute(:generated_at, Time.now)
          else
            publish(subject, payload_body)
            save_payload_body(payload_body)
            if hook_defined?(:after_publish)
              after_publish(subject)
            end
          end
        end
      end
    end

    private

    def dedupe(&block)
      redis_lock = "#{self.class.name}:#{@subject_id}"
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
        self.class.perform_in(1 + rand(10), @subject_id, @enqueue_time_str)
      end
    end

    def enqueue_time
      @enqueue_time ||= Time.parse(@enqueue_time_str)
    end

    def hook_defined?(hook)
      !!self.class.hooks[hook]
    end

    def performed_since_enqueue_time?
      previous_payload && previous_payload.generated_at > enqueue_time
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

    def save_payload_body(payload_body)
      if previous_payload
        previous_payload.update_attributes(
          body: payload_body, generated_at: Time.now
        )
      else
        payload_class.create!(
          body: payload_body, generated_at: Time.now, subject_id: @subject_id
        )
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
