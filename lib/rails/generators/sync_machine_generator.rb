require "rails/generators"

# Generate SyncMachine files.
class SyncMachineGenerator < Rails::Generators::NamedBase
  class_option :subject, type: :string
  source_root File.expand_path('templates', __dir__)

  hook_for :orm
  hook_for :test_framework

  def create_sync_file
    template "sync.rb", "app/services/#{file_path}.rb"
  end

  def create_find_subjects_worker_file
    template(
      "find_subjects_worker.rb",
      "app/workers/#{file_path}/find_subjects_worker.rb"
    )
  end

  def create_ensure_publication_worker_file
    template(
      "ensure_publication_worker.rb",
      "app/workers/#{file_path}/ensure_publication_worker.rb"
    )
  end

  def create_change_listener_file
    template(
      "change_listener.rb", "app/services/#{file_path}/change_listener.rb"
    )
  end

  def append_subscribe_to_initializer
    initializer_path = "config/initializers/sync_machines.rb"
    create_file(initializer_path, "") unless File.exist?(initializer_path)
    append_to_file(
      initializer_path, "#{class_name}::ChangeListener.subscribe\n"
    )
  end

  private

  def subject
    options['subject'] || file_name.split(/_to_/).first
  end
end
