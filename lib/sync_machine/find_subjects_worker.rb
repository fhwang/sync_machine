require "sidekiq"

module SyncMachine
  # After one observed model has changed, find all relevant subjects whose
  # documents may have changed.  Enqueues one EnsurePublicationWorker job for
  # each relevant subject.
  class FindSubjectsWorker
    include Sidekiq::Worker

    class_attribute :hooks

    def self.inherited(subclass)
      subclass.hooks = {}
    end

    def self.method_missing(meth, *args, &block)
      if meth.to_s =~ /^subject_ids_from_.*/
        hooks[meth] = Hook.new(block)
      else
        super
      end
    end

    # :reek:LongParameterList is unavoidable here since this is a Sidekiq
    # worker
    def perform(record_class_name, record_id, changed_keys, enqueue_time)
      record = record_class_name.constantize.find(record_id)
      source_ids = find_source_ids(record, changed_keys)
      (source_ids || []).each do |source_id|
        self.class.parent.const_get('EnsurePublicationWorker').perform_async(
          source_id, enqueue_time
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
      def initialize(block)
        @block = block
      end

      def call(record, changed_keys)
        raw_source_ids = if @block.arity == 2
                           @block.call(record, changed_keys)
                         else
                           @block.call(record)
                         end
        Array.wrap(raw_source_ids).map { |raw_source_id|
          SyncMachine.orm_adapter.record_id_for_job(raw_source_id)
        }
      end
    end
  end
end
