require "active_support/json"
require "active_support/core_ext/object/json"
require "wisper"

module SyncMachine
  # Listen to changes in any model that could result in a change to the
  # published document, and enqueue a FindSubjectsWorker job when the change
  # occurs.
  class ChangeListener
    def self.inherited(base)
      base.cattr_accessor :model_syms do
        []
      end
    end

    def self.define_method_matching_wisper_event(event)
      define_method(event) do |subject|
        find_subjects_async(subject)
      end
    end

    def self.listen_to_models(*model_syms)
      self.model_syms = model_syms
      model_syms.each do |model_sym|
        send(
          :alias_method,
          "update_#{model_sym}_successful".to_sym,
          :after_record_saved
        )
      end
    end

    def self.listen_to_wisper_events(*events)
      events.each do |event|
        define_method_matching_wisper_event(event)
      end
    end

    def self.subscribe
      Wisper.subscribe(new)
    end

    def after_create(record)
      model_sym = record.class.name.underscore.to_sym
      return unless self.class.model_syms.include?(model_sym)
      after_record_saved(record)
    end

    def after_record_saved(record)
      return unless orm_adapter.sufficient_changes_to_find_subjects?(record)
      find_subjects_async(record)
    end

    private

    def find_subjects_async(record)
      sync_module = SyncMachine.sync_module(self.class)
      finder_class = sync_module.const_get('FindSubjectsWorker')
      finder_class.perform_async_for_record(record)
    end

    def orm_adapter
      SyncMachine.sync_module(self.class).orm_adapter
    end
  end
end
