require "active_support/core_ext/class"
require "active_support/core_ext/string"
require "mongoid"
require "sync_machine/change_listener"
require "sync_machine/ensure_publication_worker"
require "sync_machine/ensure_publication_worker/deduper"
require "sync_machine/ensure_publication_worker/publisher"
require "sync_machine/find_subjects_worker"
require "sync_machine/version"
require "wisper/mongoid"

module SyncMachine
  class Error < StandardError; end

  def self.extended(base)
    base.mattr_accessor :subject_sym
  end

  def subject(subject_sym)
    self.subject_sym = subject_sym
  end

  def subject_class
    self.subject_sym.to_s.camelize.constantize
  end

  def setup
    unless const_defined?('Payload')
      collection_name = self.name.underscore + '_payloads'
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
    const_get('ChangeListener').subscribe
  end
end

Wisper::Mongoid.extend_all
