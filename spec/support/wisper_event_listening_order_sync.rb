module WisperEventListeningOrderSync
  extend SyncMachine

  subject :order

  class WisperBroadcaster
    include Wisper::Publisher

    def broadcast_wisper_event(order)
      broadcast(:after_order_broadcast, order)
    end
  end

  class ChangeListener < SyncMachine::ChangeListener
    listen_to_wisper_events :after_order_broadcast

    #def after_order_broadcast(order)
      #puts "after_order_broadcast 0"
    #end
    #def method_missing(meth, *args)
      #if meth == :after_order_broadcast
        #puts "after_order_broadcast 0"
      #else
        #super
      #end
    #end
  end

  ChangeListener.subscribe

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
