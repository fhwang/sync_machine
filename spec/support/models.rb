class Customer
  include Mongoid::Document

  field :name, type: String

  has_many :orders
end

class Order
  include Mongoid::Document

  field :next_payload, type: Hash, default: {"foo" => "bar"}
  field :publishable, type: Boolean, default: true

  belongs_to :customer
end
