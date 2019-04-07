require 'spec_helper'

RSpec.describe SyncMachine::ChangeListener do
  describe 'for an ActiveRecord-based application' do
    before do
      setup_active_record
      TestActiveRecordSync::FindSubjectsWorker.clear
    end

    it "enqueues a FindSubjectsWorker when a model is created" do
      test_sync_subject = ActiveRecordCustomer.create!
      expect(TestActiveRecordSync::FindSubjectsWorker.jobs.count).to eq(1)
      args = TestActiveRecordSync::FindSubjectsWorker.jobs.first['args']
      expect(args.size).to eq(4)
      expect(args[0]).to eq('ActiveRecordCustomer')
      expect(args[1]).to eq(test_sync_subject.id)
      expect(args[2]).to eq(['id'])
      expect(Time.parse(args[3])).to be_within(1).of(Time.now)
    end

    it "includes changed keys on an update" do
      test_sync_subject = ActiveRecordCustomer.create!
      TestActiveRecordSync::FindSubjectsWorker.clear
      expect(TestActiveRecordSync::FindSubjectsWorker.jobs.count).to eq(0)
      test_sync_subject.name = "new name"
      test_sync_subject.save!
      expect(TestActiveRecordSync::FindSubjectsWorker.jobs.count).to eq(1)
      args = TestActiveRecordSync::FindSubjectsWorker.jobs.first['args']
      expect(args.size).to eq(4)
      expect(args[0]).to eq('ActiveRecordCustomer')
      expect(args[1]).to eq(test_sync_subject.id)
      expect(args[2]).to eq(['name'])
      expect(Time.parse(args[3])).to be_within(1).of(Time.now)
    end
  end

  describe 'for a Mongoid-based application' do
    before do
      setup_mongoid
      TestMongoidSync::FindSubjectsWorker.clear
    end

    it "enqueues a FindSubjectsWorker when a model is created" do
      test_sync_subject = MongoidCustomer.create!
      expect(TestMongoidSync::FindSubjectsWorker.jobs.count).to eq(1)
      args = TestMongoidSync::FindSubjectsWorker.jobs.first['args']
      expect(args.size).to eq(4)
      expect(args[0]).to eq('MongoidCustomer')
      expect(args[1]).to eq(test_sync_subject.id.to_s)
      expect(args[2]).to eq(['_id'])
      expect(Time.parse(args[3])).to be_within(1).of(Time.now)
    end
  end
end
