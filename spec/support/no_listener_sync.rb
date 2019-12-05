module NoListenerSync
  extend SyncMachine

  subject :order

  class FindSubjectsWorker < SyncMachine::FindSubjectsWorker
    subject_ids_from_order
  end

  class EnsurePublicationWorker < SyncMachine::EnsurePublicationWorker
    check_publishable do |subject|
    end

    build do |subject|
    end

    publish do |_subject, payload_body|
    end
  end
end
