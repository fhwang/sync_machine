require "rails/generators"

module Rspec
  # Generate SyncMachine files for RSpec.
  class SyncMachineGenerator < ::Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)

    def create_service_spec_file
      template "service_spec.rb", "spec/services/#{file_path}_spec.rb"
    end
  end
end

