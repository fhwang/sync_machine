require 'active_record'

def create_tables_for_models
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Schema.define do
    create_table :customers, force: true do |t|
      t.string :name
    end

    create_table :orders, force: true do |t|
      t.string :next_payload
      t.boolean :publishable
      t.integer :customer_id
    end

    create_table :order_sync_payloads, force: true do |t|
      t.text :body
      t.datetime  :generated_at
      t.integer   :subject_id
    end

    create_table :no_check_publishable_sync_payloads, force: true do |t|
      t.text :body
      t.datetime  :generated_at
      t.integer   :subject_id
    end
  end
end

class Customer < ActiveRecord::Base
  has_many :orders
end

class Order < ActiveRecord::Base
  serialize :next_payload

  belongs_to :customer
end

module OrderSync
  class Payload < ActiveRecord::Base
    self.table_name = 'order_sync_payloads'

    serialize :body

    validates :generated_at, presence: true
    validates :subject_id, presence: true, uniqueness: true
  end
end

module NoCheckPublishableSync
  class Payload < ActiveRecord::Base
    self.table_name = 'no_check_publishable_sync_payloads'

    serialize :body

    validates :generated_at, presence: true
    validates :subject_id, presence: true, uniqueness: true
  end
end

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)
create_tables_for_models
