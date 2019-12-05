require "sidekiq"

module SyncMachine
  # After one observed model has changed, find all relevant subjects whose
  # documents may have changed.  Enqueues one EnsurePublicationWorker job for
  # each relevant subject.
  class FindSubjectsWorker
    include Sidekiq::Worker

    class_attribute :hooks

    def self.add_hook(meth, block)
      sync_module = SyncMachine.sync_module(self)
      hooks[meth] = Hook.new(meth.to_s, sync_module, block)
    end
    private_class_method :add_hook

    def self.inherited(subclass)
      subclass.hooks = {}
    end

    def self.method_missing(meth, *args, &block)
      if meth.to_s == "subject_ids_from_#{parent.subject_sym}"
        block ||= ->(subject) { [subject.id.to_s] }
        add_hook(meth, block)
      elsif meth.to_s =~ /^subject_ids_from_.*/
        add_hook(meth, block)
      else
        super
      end
    end

    def self.perform_async_for_record(record)
      sync_module = SyncMachine.sync_module(self)
      orm_adapter = sync_module.orm_adapter
      record_id_for_job = orm_adapter.record_id_for_job(record.id)
      changed_keys = orm_adapter.change_listener_changed_keys(record)
      perform_async(
        record.class.name, record_id_for_job, changed_keys, Time.now.to_json
      )
    end

    # :reek:LongParameterList is unavoidable here since this is a Sidekiq
    # worker
    def perform(record_class_name, record_id, changed_keys, enqueue_time_str)
      record = record_class_name.constantize.find(record_id)
      source_ids = find_source_ids(record, changed_keys)
      (source_ids || []).each do |source_id|
        self.class.parent.const_get('EnsurePublicationWorker').perform_async(
          source_id, enqueue_time_str
        )
      end
    end

    private

    def find_source_ids(record, changed_keys)
      hook_name = (
        "subject_ids_from_" + record.class.name.gsub(/::/, '').underscore).to_sym
      self.class.hooks[hook_name].call(record, changed_keys)
    end

    # Wrap a "subject_ids_from_*" block.
    class Hook
      def initialize(name, sync_module, block)
        @name = name.to_s
        @sync_module = sync_module
        @block = block
      end

      def call(record, changed_keys)
        TracerAdapters.tracer_adapter.start_active_span(@name) do
          raw_source_ids = if @block.arity == 2
                             @block.call(record, changed_keys)
                           else
                             @block.call(record)
                           end
          Array.wrap(raw_source_ids).map { |raw_source_id|
            @sync_module.orm_adapter.record_id_for_job(raw_source_id)
          }
        end
      end
    end
  end
end
