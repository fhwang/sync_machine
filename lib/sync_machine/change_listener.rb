require "wisper"

module SyncMachine
  # Listen to changes in any model that could result in a change to the
  # published document, and enqueue a FindSubjectsWorker job when the change
  # occurs.
  class ChangeListener
    def self.inherited(base)
      base.cattr_accessor :model_syms
    end

    def self.listen_to_models(*model_syms)
      self.model_syms = model_syms
      model_syms.each do |model_sym|
        send(
          :alias_method,
          "update_#{model_sym}_successful".to_sym,
          :after_subject_saved
        )
      end
    end

    def self.subscribe
      Wisper.subscribe(new)
    end

    def after_create(subject)
      model_sym = subject.class.name.underscore.to_sym
      return unless self.class.model_syms.include?(model_sym)
      after_subject_saved(subject)
    end

    def after_subject_saved(subject)
      return unless changed_keys(subject).present?
      sync_module = SyncMachine.sync_module(self.class)
      finder_class = sync_module.const_get('FindSubjectsWorker')
      finder_class.perform_async(
        subject.class.name,
        subject.id.to_s,
        changed_keys(subject),
        Time.now.iso8601
      )
    end

    private

    def changed_keys(subject)
      changed_keys = subject.changes.keys
      subject.class.reflect_on_all_associations.each do |assoc|
        if assoc.macro == :embeds_one && subject.send(assoc.name).try(:changed?)
          changed_keys << assoc.name
        end
      end
      changed_keys
    end
  end
end
