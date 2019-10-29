require "wisper"

module SyncMachine
  # Listen to changes in any model that could result in a change to the
  # published document, and enqueue a FindSubjectsWorker job when the change
  # occurs.
  class ChangeListener
    def self.inherited(base)
      base.cattr_accessor :model_syms
      base.subscribe
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
      sync_module = SyncMachine.sync_module(self.class)
      finder_class = sync_module.const_get('FindSubjectsWorker')
      finder_class.perform_async(
        record.class.name,
        record_id_for_job(record.id),
        changed_keys(record),
        Time.now.iso8601
      )
    end

    private

    def changed_keys(record)
      orm_adapter.change_listener_changed_keys(record)
    end

    def record_id_for_job(record_id)
      orm_adapter.record_id_for_job(record_id)
    end

    def orm_adapter
      SyncMachine.orm_adapter
    end
  end
end
