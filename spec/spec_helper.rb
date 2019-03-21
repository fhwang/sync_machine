require "bundler/setup"
require "factory_bot"
require "sync_machine"
require "sidekiq/testing"

Dir.entries(File.expand_path("../support", __FILE__)).each do |file|
  require "support/#{file}" if file =~ /\.rb$/
end

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

Mongoid.load!("./spec/mongoid.yml", :test)
