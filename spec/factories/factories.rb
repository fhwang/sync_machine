FactoryBot.define do
  factory :customer

  factory :order do
    customer
  end

  factory :mongoid_customer

  factory :mongoid_order do
    mongoid_customer
  end
end
