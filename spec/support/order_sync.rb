module OrderSync
  extend SyncMachine

  subject :order

  class ChangeListener < SyncMachine::ChangeListener
    listen_to_models :order, :customer
  end

  ChangeListener.subscribe

  class FindSubjectsWorker < SyncMachine::FindSubjectsWorker
    subject_ids_from_customer do |customer|
      customer.order_ids
    end

    subject_ids_from_order
  end

  class EnsurePublicationWorker < SyncMachine::EnsurePublicationWorker
    check_publishable do |subject|
      subject.publishable?
    end

    build do |subject|
      subject.next_payload
    end

    publish do |_subject, payload_body|
      PostService.post(payload_body)
    end

    after_publish do |subject|
      PostService.after_post(subject)
    end
  end

  class PostService
    def self.after_post(_subject)
    end

    def self.post(_payload_body)
    end
  end
end
