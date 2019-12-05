module NoCheckPublishableSync
  extend SyncMachine

  subject :order

  class ChangeListener < SyncMachine::ChangeListener
    listen_to_models :order, :customer
  end

  ChangeListener.subscribe

  class FindSubjectsWorker < SyncMachine::FindSubjectsWorker
    subject_ids_from_order
  end

  class EnsurePublicationWorker < SyncMachine::EnsurePublicationWorker
    build do |subject|
      Builder.build
    end

    publish do |_subject, payload_body|
    end

    after_publish do |subject|
    end
  end

  class Builder
    def self.build
    end
  end
end
