module CustomerSync
  extend SyncMachine

  subject :customer

  class ChangeListener < SyncMachine::ChangeListener
    listen_to_models :order, :customer
  end

  ChangeListener.subscribe

  class FindSubjectsWorker < SyncMachine::FindSubjectsWorker
    subject_ids_from_customer do |customer|
      "ARC#{customer.id}"
    end

    subject_ids_from_order do |order|
      order.customer_id
    end
  end

  class EnsurePublicationWorker < SyncMachine::EnsurePublicationWorker
    check_publishable do |subject|
      true
    end

    build do |subject|
      {}
    end

    publish do |_subject, payload_body|
    end

    after_publish do |subject|
    end
  end
end
