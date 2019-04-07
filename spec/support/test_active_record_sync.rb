module TestActiveRecordSync
  extend SyncMachine

  subject :active_record_order

  class ChangeListener < SyncMachine::ChangeListener
    listen_to_models :active_record_customer
  end

  class FindSubjectsWorker < SyncMachine::FindSubjectsWorker
    subject_ids_from_active_record_customer do |active_record_customer|
      active_record_customer.active_record_order_ids
    end

    subject_ids_from_active_record_order do |active_record_order|
      active_record_order.id
    end
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
