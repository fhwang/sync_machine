require 'rails_helper'

describe <%= class_name %> do
  before do
    SyncMachine.eager_load(<%= class_name %>)
    clear_workers
  end

  def clear_workers
    <%= class_name %>::FindSubjectsWorker.clear
    <%= class_name %>::EnsurePublicationWorker.clear
  end

  def drain_workers
    <%= class_name %>::FindSubjectsWorker.drain
    <%= class_name %>::EnsurePublicationWorker.drain
  end
end
