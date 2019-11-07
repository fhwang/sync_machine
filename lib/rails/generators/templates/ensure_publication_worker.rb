module <%= class_name %>
  class EnsurePublicationWorker < SyncMachine::EnsurePublicationWorker
    check_publishable do |<%= subject %>|
      # Return a boolean value indicating whether the <%= subject %>
      # should be published at all.
    end

    build do |<%= subject %>|
      # Generate and return a payload to send to the external service.
    end

    publish do |<%= subject %>, payload|
      # Send the payload to the external service.
    end

    after_publish do |<%= subject %>|
      # Execute any actions after a successful publish.  This step is optional
      # and can be deleted entirely.
    end
  end
end

