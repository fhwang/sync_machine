FactoryBot.define do
  factory :customer

  factory :order do
    customer
  end
end

