require "rails/generators"

module ActiveRecord
  # Generate SyncMachine files for ActiveRecord.
  class SyncMachineGenerator < Rails::Generators::NamedBase
    class_option :subject, type: :string
    source_root File.expand_path('templates', __dir__)

    def create_payload_file
      template "payload.rb", "app/models/#{file_path}/payload.rb"
    end

    def create_payload_migration
      generate(
        "migration",
        "create_#{singular_name}_payloads body:text generated_at:datetime subject_id:integer"
      )
    end

    private

    def subject
      options['subject'] || file_name.split(/_to_/).first
    end
  end
end

