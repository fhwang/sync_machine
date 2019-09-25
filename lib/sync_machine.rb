require "active_support/core_ext/class"
require "active_support/core_ext/string"
require "active_support/hash_with_indifferent_access"
require "sync_machine/change_listener"
require "sync_machine/ensure_publication"
require "sync_machine/ensure_publication/deduper"
require "sync_machine/ensure_publication/publication_history"
require "sync_machine/ensure_publication_worker"
require "sync_machine/find_subjects_worker"
require "sync_machine/version"

# A mini-framework for intelligently publishing complex model changes to an
# external API..
module SyncMachine
  # Force loading of all relevant classes.  Should only be necessary when
  # running your application in a way that it defers loading constants, i.e.,
  # Rails' development or test mode.
  def self.eager_load(base)
    const_names = %w(
      Payload FindSubjectsWorker EnsurePublicationWorker ChangeListener
    )
    const_names.each do |const_name|
      base.const_get(const_name)
    end
  end

  def self.extended(base)
    base.mattr_accessor :subject_sym
    base.mattr_accessor :subject_opts
  end

  def self.sync_module(child_const)
    child_const.name.split(/::/)[0..-2].join('::').constantize
  end

  def subject(subject_sym, opts = {})
    self.subject_sym = subject_sym
    self.subject_opts = ActiveSupport::HashWithIndifferentAccess.new(opts)
  end

  def subject_class
    (subject_opts[:class_name] || subject_sym.to_s.camelize).constantize
  end
end
