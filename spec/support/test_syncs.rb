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
