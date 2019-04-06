module TestMongoidSync
  extend SyncMachine

  subject :mongoid_order

  class ChangeListener < SyncMachine::ChangeListener
    listen_to_models :mongoid_customer
  end

  class FindSubjectsWorker < SyncMachine::FindSubjectsWorker
    subject_ids_from_mongoid_customer do |mongoid_customer|
      mongoid_customer.mongoid_order_ids
    end

    subject_ids_from_mongoid_order do |mongoid_order|
      mongoid_order.id
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
