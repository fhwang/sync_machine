require "wisper"

module SyncMachine
  class ChangeListener
    def self.inherited(base)
      base.cattr_accessor :model_syms
    end

    def self.listen_to_models(*model_syms)
      self.model_syms = model_syms
      model_syms.each do |model_sym|
        self.send(
          :alias_method,
          "update_#{model_sym}_successful".to_sym,
          :after_subject_saved
        )
      end
    end

    def self.subscribe
      Wisper.subscribe(self.new)
    end

    def after_create(subject)
      if self.class.model_syms.include?(subject.class.name.underscore.to_sym)
        after_subject_saved(subject)
      end
    end

    def after_subject_saved(subject)
      changed_keys = subject.changes.keys
      subject.class.reflect_on_all_associations.each do |assoc|
        if assoc.macro == :embeds_one && subject.send(assoc.name).try(:changed?)
          changed_keys << assoc.name
        end
      end
      if changed_keys.present?
        finder_class = Module.const_get(self.class.name.split(/::/).first).const_get('FindSubjectsWorker')
        finder_class.perform_async(
          subject.class.name, subject.id.to_s, changed_keys, Time.now.iso8601
        )
      end
    end
  end
end
