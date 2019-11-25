module OuterNesting
  module NestedSync
    extend SyncMachine

    class ChangeListener < SyncMachine::ChangeListener
      listen_to_models :subject
    end

    ChangeListener.subscribe
  end
end

module ClassNameTestModule
  class Subject

  end

  module Sync
    extend SyncMachine

    subject :subject, class_name: 'ClassNameTestModule::Subject'
  end
end
