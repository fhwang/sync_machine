module ActiveRecordCustomerSync
  extend SyncMachine

  subject :active_record_customer

  class ChangeListener < SyncMachine::ChangeListener
    listen_to_models :active_record_order, :active_record_customer
  end

  ChangeListener.subscribe

  class FindSubjectsWorker < SyncMachine::FindSubjectsWorker
    subject_ids_from_active_record_customer do |active_record_customer|
      "ARC#{active_record_customer.id}"
    end

    subject_ids_from_active_record_order do |active_record_order|
      active_record_order.active_record_customer_id
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
