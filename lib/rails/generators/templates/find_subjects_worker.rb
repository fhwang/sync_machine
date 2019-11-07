module <%= class_name %>
  class FindSubjectsWorker < SyncMachine::FindSubjectsWorker
    subject_ids_from_<%= subject %>
  end
end
