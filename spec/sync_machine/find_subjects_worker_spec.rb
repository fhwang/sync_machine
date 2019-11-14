require 'spec_helper'

RSpec.describe SyncMachine::FindSubjectsWorker do
  describe "when the ORM is ActiveRecord" do
    before do
      ActiveRecordOrderSync::EnsurePublicationWorker.clear
      ActiveRecordCustomerSync::EnsurePublicationWorker.clear
    end

    it "enqueues one EnsurePublicationWorker for each subject_id" do
      customer = create(:active_record_customer)
      order1 = create(:active_record_order, active_record_customer: customer)
      order2 = create(:active_record_order, active_record_customer: customer)
      enqueue_time_str = Time.now.iso8601
      ActiveRecordOrderSync::FindSubjectsWorker.new.perform(
        'ActiveRecordCustomer', customer.id, ['name'], enqueue_time_str
      )
      expect(ActiveRecordOrderSync::EnsurePublicationWorker.jobs.count).to eq(2)
      jobs = ActiveRecordOrderSync::EnsurePublicationWorker.jobs
      [order1, order2].each do |order|
        order_job = jobs.detect { |j| j['args'].first == order.id }
        expect(order_job).to be_present
        expect(order_job['args'].count).to eq(2)
        expect(order_job['args'].last).to eq(enqueue_time_str)
      end
    end

    it "handles blocks that don't return an array" do
      order = create(:active_record_order)
      enqueue_time_str = Time.now.iso8601
      ActiveRecordCustomerSync::FindSubjectsWorker.new.perform(
        'ActiveRecordOrder', order.id, ['name'], enqueue_time_str
      )
      expect(ActiveRecordCustomerSync::EnsurePublicationWorker.jobs.count).to \
        eq(1)
      job = ActiveRecordCustomerSync::EnsurePublicationWorker.jobs.first
      expect(job['args'].count).to eq(2)
      expect(job['args'].first).to eq(order.active_record_customer_id)
      expect(job['args'].last).to eq(enqueue_time_str)
    end

    it "handles the default case" do
      order = create(:active_record_order)
      enqueue_time_str = Time.now.iso8601
      ActiveRecordOrderSync::FindSubjectsWorker.new.perform(
        'ActiveRecordOrder', order.id.to_s, ['name'], enqueue_time_str
      )
      expect(ActiveRecordOrderSync::EnsurePublicationWorker.jobs.count).to eq(1)
      job = ActiveRecordOrderSync::EnsurePublicationWorker.jobs.first
      expect(job['args'].count).to eq(2)
      expect(job['args'].first).to eq(order.id.to_s)
      expect(job['args'].last).to eq(enqueue_time_str)
    end

    it "allows a manual override of the default case and wraps a single ID in an array" do
      customer = create(:active_record_customer)
      enqueue_time_str = Time.now.iso8601
      ActiveRecordCustomerSync::FindSubjectsWorker.new.perform(
        'ActiveRecordCustomer', customer.id.to_s, ['name'], enqueue_time_str
      )
      expect(ActiveRecordCustomerSync::EnsurePublicationWorker.jobs.count).to \
        eq(1)
      job = ActiveRecordCustomerSync::EnsurePublicationWorker.jobs.first
      expect(job['args'].count).to eq(2)
      expect(job['args'].first).to eq("ARC#{customer.id.to_s}")
      expect(job['args'].last).to eq(enqueue_time_str)
    end
  end

  describe "when the ORM is Mongoid" do
    before do
      MongoidSync::EnsurePublicationWorker.clear
    end

    it "enqueues one EnsurePublicationWorker for each subject_id" do
      customer = create(:mongoid_customer)
      order1 = create(:mongoid_order, mongoid_customer: customer)
      order2 = create(:mongoid_order, mongoid_customer: customer)
      enqueue_time_str = Time.now.iso8601
      MongoidSync::FindSubjectsWorker.new.perform(
        'MongoidCustomer', customer.id.to_s, ['name'], enqueue_time_str
      )
      expect(MongoidSync::EnsurePublicationWorker.jobs.count).to eq(2)
      jobs = MongoidSync::EnsurePublicationWorker.jobs
      [order1, order2].each do |order|
        order_job = jobs.detect { |j|
          j['args'].first == order.id.to_s
        }
        expect(order_job).to be_present
        expect(order_job['args'].count).to eq(2)
        expect(order_job['args'].last).to eq(enqueue_time_str)
      end
    end
  end
end
