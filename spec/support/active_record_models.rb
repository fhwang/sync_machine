def create_tables_for_active_record_models
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Schema.define do
    create_table :active_record_customers, force: true do |t|
      t.string :name
    end

    create_table :active_record_orders, force: true do |t|
      t.string :next_payload
      t.boolean :publishable
      t.integer :active_record_customer_id
    end

    create_table :test_active_record_sync_payloads, force: true do |t|
      t.text :body
      t.datetime  :generated_at
      t.integer   :subject_id
    end
  end
end

class ActiveRecordCustomer < ActiveRecord::Base
  has_many :active_record_orders
end

class ActiveRecordOrder < ActiveRecord::Base
  serialize :next_payload

  belongs_to :active_record_customer
end

module TestActiveRecordSync
  def self.table_name_prefix
    'test_active_record_sync_'
  end

  class Payload < ActiveRecord::Base
    serialize :body

    validates :generated_at, presence: true
    validates :subject_id, presence: true, uniqueness: true
  end
end
