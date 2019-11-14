FactoryBot.define do
  factory :active_record_customer

  factory :active_record_order do
    active_record_customer
  end

  factory :mongoid_customer

  factory :mongoid_order do
    mongoid_customer
  end
end
