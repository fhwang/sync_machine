class MongoidCustomer
  include Mongoid::Document

  field :name, type: String

  has_many :mongoid_orders
end

class MongoidOrder
  include Mongoid::Document

  field :next_payload, type: Hash, default: {"foo" => "bar"}
  field :publishable, type: Boolean, default: true

  belongs_to :mongoid_customer
end

module TestMongoidSync
  class Payload
    include ::Mongoid::Document

    field :body, type: Hash
    field :generated_at, type: Time
    field :subject_id, type: String

    validates :generated_at, presence: true
    validates :subject_id, presence: true, uniqueness: true
  end
end
