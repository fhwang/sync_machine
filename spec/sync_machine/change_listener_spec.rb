require 'spec_helper'

RSpec.describe SyncMachine::ChangeListener do
  describe "after a record has been updated" do
    subject { TestSync::ChangeListener.new }

    it "enqueues with an enqueue_time with millisecond precision" do
      record = double('record', id: 123, previous_changes: {foo: 'bar'})
      subject.after_record_saved(record)
      expect(TestSync::FindSubjectsWorker.jobs).to be_present
      args = TestSync::FindSubjectsWorker.jobs.first['args']
      enqueue_time_str = args[3]
      enqueue_time = Time.parse(enqueue_time_str)
      expect(enqueue_time.to_f > enqueue_time.to_i).to eq(true)
    end
  end
end
