require "sidekiq"

module SyncMachine
  class FindSubjectsWorker
    include Sidekiq::Worker

    class_attribute :hooks

    def self.inherited(subclass)
      subclass.hooks = {}
    end

    def self.method_missing(meth, *args, &block)
      if meth.to_s =~ /^subject_ids_from_.*/
        self.hooks[meth] = block
      else
        super
      end
    end

    def perform(record_class_name, record_id, changed_keys, enqueue_time)
      record = record_class_name.constantize.find(record_id)
      hook_name =
        ("subject_ids_from_" +
        record_class_name.gsub(/::/, '').underscore).to_sym
      hook = self.class.hooks[hook_name]
      raw_source_ids = if hook.arity == 2
                     hook.call(record, changed_keys)
                   else
                     hook.call(record)
                   end
      source_ids = Array.wrap(raw_source_ids).map(&:to_s)
      (source_ids || []).each do |source_id|
        self.class.parent.const_get('EnsurePublicationWorker').perform_async(
          source_id, enqueue_time
        )
      end
    end
  end
end
