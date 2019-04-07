require "active_support/core_ext/class"
require "active_support/core_ext/string"
require "sync_machine/change_listener"
require "sync_machine/ensure_publication"
require "sync_machine/ensure_publication/deduper"
require "sync_machine/ensure_publication/publication_history"
require "sync_machine/ensure_publication_worker"
require "sync_machine/find_subjects_worker"
require "sync_machine/orm_adapter/active_record"
require "sync_machine/orm_adapter/mongoid"
require "sync_machine/version"

# A mini-framework for intelligently publishing complex model changes to an
# external API..
module SyncMachine
  mattr_accessor :orm_adapter

  def self.use_active_record
    setup_orm_adapter(OrmAdapter::ActiveRecord)
  end

  def self.use_mongoid
    setup_orm_adapter(OrmAdapter::Mongoid)
  end

  def self.setup_orm_adapter(orm_adapter)
    self.orm_adapter = orm_adapter
    orm_adapter.setup
  end

  def self.extended(base)
    base.mattr_accessor :subject_sym

    # Force loading of all relevant classes.  Should only be necessary when
    # running your application in a way that it defers loading constants, i.e.,
    # Rails' development or test mode.
    def base.eager_load
      const_names = %w(
        Payload FindSubjectsWorker EnsurePublicationWorker ChangeListener
      )
      const_names.each do |const_name|
        const_get(const_name)
      end
    end
  end

  def self.sync_module(child_const)
    child_const.name.split(/::/).first.constantize
  end

  def subject(subject_sym)
    self.subject_sym = subject_sym
  end

  def subject_class
    subject_sym.to_s.camelize.constantize
  end
end
