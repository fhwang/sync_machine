require 'spec_helper'

RSpec.describe SyncMachine::FindSubjectsWorker do
  describe 'for an ActiveRecord-based application' do
    before do
      setup_active_record
      TestActiveRecordSync::EnsurePublicationWorker.clear
    end

    it "enqueues one EnsurePublicationWorker for each subject_id" do
      active_record_customer = create(:active_record_customer)
      order1 = create(
        :active_record_order, active_record_customer: active_record_customer
      )
      order2 = create(
        :active_record_order, active_record_customer: active_record_customer
      )
      enqueue_time_str = Time.now.iso8601
      TestActiveRecordSync::FindSubjectsWorker.new.perform(
        'ActiveRecordCustomer',
        active_record_customer.id,
        ['name'],
        enqueue_time_str
      )
      expect(TestActiveRecordSync::EnsurePublicationWorker.jobs.count).to eq(2)
      jobs = TestActiveRecordSync::EnsurePublicationWorker.jobs
      [order1, order2].each do |order|
        order_job = jobs.detect { |j|
          j['args'].first == order.id
        }
        expect(order_job).to be_present
        expect(order_job['args'].count).to eq(2)
        expect(order_job['args'].last).to eq(enqueue_time_str)
      end
    end

    it "wraps a single ID in an array" do
      order = create(:active_record_order)
      enqueue_time_str = Time.now.iso8601
      TestActiveRecordSync::FindSubjectsWorker.new.perform(
        'ActiveRecordOrder', order.id, ['name'], enqueue_time_str
      )
      expect(TestActiveRecordSync::EnsurePublicationWorker.jobs.count).to eq(1)
      job = TestActiveRecordSync::EnsurePublicationWorker.jobs.first
      expect(job['args'].count).to eq(2)
      expect(job['args'].first).to eq(order.id)
      expect(job['args'].last).to eq(enqueue_time_str)
    end
  end

  describe 'for a Mongoid-based application' do
    before do
      setup_mongoid
      TestMongoidSync::EnsurePublicationWorker.clear
    end

    it "enqueues one EnsurePublicationWorker for each subject_id" do
      mongoid_customer = create(:mongoid_customer)
      order1 = create(:mongoid_order, mongoid_customer: mongoid_customer)
      order2 = create(:mongoid_order, mongoid_customer: mongoid_customer)
      enqueue_time_str = Time.now.iso8601
      TestMongoidSync::FindSubjectsWorker.new.perform(
        'MongoidCustomer', mongoid_customer.id.to_s, ['name'], enqueue_time_str
      )
      expect(TestMongoidSync::EnsurePublicationWorker.jobs.count).to eq(2)
      jobs = TestMongoidSync::EnsurePublicationWorker.jobs
      [order1, order2].each do |order|
        order_job = jobs.detect { |j|
          j['args'].first == order.id.to_s
        }
        expect(order_job).to be_present
        expect(order_job['args'].count).to eq(2)
        expect(order_job['args'].last).to eq(enqueue_time_str)
      end
    end

    it "wraps a single ID in an array" do
      order = create(:mongoid_order)
      enqueue_time_str = Time.now.iso8601
      TestMongoidSync::FindSubjectsWorker.new.perform(
        'MongoidOrder', order.id.to_s, ['name'], enqueue_time_str
      )
      expect(TestMongoidSync::EnsurePublicationWorker.jobs.count).to eq(1)
      job = TestMongoidSync::EnsurePublicationWorker.jobs.first
      expect(job['args'].count).to eq(2)
      expect(job['args'].first).to eq(order.id.to_s)
      expect(job['args'].last).to eq(enqueue_time_str)
    end
  end
end
