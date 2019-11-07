module <%= class_name %>
  class ChangeListener < SyncMachine::ChangeListener
    listen_to_models :<%= subject %>
  end
end
