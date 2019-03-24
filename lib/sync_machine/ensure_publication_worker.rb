require "active_support/core_ext/class"
require "sidekiq"

module SyncMachine
  # Call EnsurePublication service via a Sidekiq job.
  class EnsurePublicationWorker
    include Sidekiq::Worker

    class_attribute :hooks

    [:build, :check_publishable, :publish, :after_publish].each do |hook|
      define_singleton_method(hook) do |&block|
        hooks[hook] = block
      end
    end

    def self.inherited(subclass)
      subclass.hooks = {}
    end

    def perform(subject_id, enqueue_time_str)
      subject = find_subject(subject_id)
      EnsurePublication.new(
        enqueue_time_str: enqueue_time_str,
        hooks: self.class.hooks,
        subject: subject,
        sync_module: SyncMachine.sync_module(self.class)
      ).run
    end

    private

    def find_subject(subject_id)
      sync_module = SyncMachine.sync_module(self.class)
      subject_class = sync_module.subject_class
      subject_class.find(subject_id)
    end
  end
end
