require "active_support/core_ext/class"
require "active_support/core_ext/string"
require "mongoid"
require "sync_machine/change_listener"
require "sync_machine/ensure_publication"
require "sync_machine/ensure_publication/deduper"
require "sync_machine/ensure_publication/publication_history"
require "sync_machine/ensure_publication_worker"
require "sync_machine/find_subjects_worker"
require "sync_machine/version"
require "wisper/mongoid"

# A mini-framework for intelligently publishing complex model changes to an
# external API..
module SyncMachine
  def self.extended(base)
    base.mattr_accessor :subject_sym
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

  def setup
    define_payload_class unless const_defined?('Payload')
    const_get('ChangeListener').subscribe
  end

  # :reek:TooManyStatements is unavoidable with this sort of dynamic class
  # definition
  def define_payload_class
    collection_name = name.underscore + '_payloads'
    payload_class = Class.new do
      include Mongoid::Document
      store_in collection: collection_name

      field :body, type: Hash
      field :generated_at, type: Time
      field :subject_id, type: String

      validates :generated_at, presence: true
      validates :subject_id, presence: true, uniqueness: true
    end
    const_set('Payload', payload_class)
  end
end

Wisper::Mongoid.extend_all
