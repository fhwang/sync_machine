require "bundler/setup"
require "factory_bot"
require "mongoid"
require "sync_machine"
require "sidekiq/testing"
require "sqlite3"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end

def setup_active_record
  SyncMachine.setup(orm: :active_record)
  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: ':memory:'
  )
  require 'support/active_record_models'
  create_tables_for_active_record_models
  require 'support/test_active_record_sync'
end

def setup_mongoid
  SyncMachine.setup(orm: :mongoid)
  require 'support/mongoid_models'
  require 'support/test_mongoid_sync'
  Mongoid.load!("./spec/mongoid.yml", :test)
end
