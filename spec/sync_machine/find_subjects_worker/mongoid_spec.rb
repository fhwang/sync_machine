require 'spec_helper'

RSpec.describe "SyncMachine::FindSubjectsWorker for Mongoid" do
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
