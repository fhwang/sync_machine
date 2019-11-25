require 'mongoid'

module MongoidSync
  extend SyncMachine

  subject :mongoid_order

  class ChangeListener < SyncMachine::ChangeListener
    listen_to_models :mongoid_customer, :mongoid_order
  end

  ChangeListener.subscribe

  class FindSubjectsWorker < SyncMachine::FindSubjectsWorker
    subject_ids_from_mongoid_customer do |mongoid_customer|
      mongoid_customer.mongoid_order_ids
    end

    subject_ids_from_mongoid_order
  end

  class EnsurePublicationWorker < SyncMachine::EnsurePublicationWorker
    check_publishable do |subject|
      subject.publishable?
    end

    build do |subject|
      subject.next_payload
    end

    publish do |_subject, payload_body|
      PostService.post(payload_body)
    end

    after_publish do |subject|
      PostService.after_post(subject)
    end
  end

  class PostService
    def self.after_post(_subject)
    end

    def self.post(_payload_body)
    end
  end
end

class MongoidAddress
  include Mongoid::Document

  field :address1,  type: String
  field :address2,  type: String
  field :city,      type: String
  field :state,     type: String
  field :zip,       type: String
end

class MongoidCustomer
  include Mongoid::Document

  field :name, type: String

  embeds_one  :mongoid_address
  has_many    :mongoid_orders
end

class MongoidOrder
  include Mongoid::Document

  field :next_payload, type: Hash, default: {"foo" => "bar"}
  field :publishable, type: Boolean, default: true

  belongs_to :mongoid_customer
end

module MongoidSync
  class Payload
    include ::Mongoid::Document

    field :body, type: Hash
    field :generated_at, type: Time
    field :subject_id, type: String

    validates :generated_at, presence: true
    validates :subject_id, presence: true, uniqueness: true
  end
end

Mongoid.load!("./spec/mongoid.yml", :test)
