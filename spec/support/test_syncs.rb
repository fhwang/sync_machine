module TestSync
  extend SyncMachine

  class ChangeListener < SyncMachine::ChangeListener
  end
end

module OuterNesting
  module NestedTestSync
    extend SyncMachine

    class ChangeListener < SyncMachine::ChangeListener
    end
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
