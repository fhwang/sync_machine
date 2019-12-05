require 'spec_helper'

RSpec.describe SyncMachine::FindSubjectsWorker do
  before do
    OrderSync::EnsurePublicationWorker.clear
    CustomerSync::EnsurePublicationWorker.clear
  end

  it "enqueues one EnsurePublicationWorker for each subject_id" do
    customer = create(:customer)
    order1 = create(:order, customer: customer)
    order2 = create(:order, customer: customer)
    enqueue_time_str = Time.now.iso8601
    OrderSync::FindSubjectsWorker.new.perform(
      'Customer', customer.id, ['name'], enqueue_time_str
    )
    expect(OrderSync::EnsurePublicationWorker.jobs.count).to eq(2)
    jobs = OrderSync::EnsurePublicationWorker.jobs
    [order1, order2].each do |order|
      order_job = jobs.detect { |j| j['args'].first == order.id }
      expect(order_job).to be_present
      expect(order_job['args'].count).to eq(2)
      expect(order_job['args'].last).to eq(enqueue_time_str)
    end
  end

  it "handles blocks that don't return an array" do
    order = create(:order)
    enqueue_time_str = Time.now.iso8601
    CustomerSync::FindSubjectsWorker.new.perform(
      'Order', order.id, ['name'], enqueue_time_str
    )
    expect(CustomerSync::EnsurePublicationWorker.jobs.count).to \
      eq(1)
    job = CustomerSync::EnsurePublicationWorker.jobs.first
    expect(job['args'].count).to eq(2)
    expect(job['args'].first).to eq(order.customer_id)
    expect(job['args'].last).to eq(enqueue_time_str)
  end

  it "handles the default case" do
    order = create(:order)
    enqueue_time_str = Time.now.iso8601
    OrderSync::FindSubjectsWorker.new.perform(
      'Order', order.id.to_s, ['name'], enqueue_time_str
    )
    expect(OrderSync::EnsurePublicationWorker.jobs.count).to eq(1)
    job = OrderSync::EnsurePublicationWorker.jobs.first
    expect(job['args'].count).to eq(2)
    expect(job['args'].first).to eq(order.id.to_s)
    expect(job['args'].last).to eq(enqueue_time_str)
  end

  it "allows a manual override of the default case and wraps a single ID in an array" do
    customer = create(:customer)
    enqueue_time_str = Time.now.iso8601
    CustomerSync::FindSubjectsWorker.new.perform(
      'Customer', customer.id.to_s, ['name'], enqueue_time_str
    )
    expect(CustomerSync::EnsurePublicationWorker.jobs.count).to \
      eq(1)
    job = CustomerSync::EnsurePublicationWorker.jobs.first
    expect(job['args'].count).to eq(2)
    expect(job['args'].first).to eq("ARC#{customer.id.to_s}")
    expect(job['args'].last).to eq(enqueue_time_str)
  end

  it "logs a span for every hook that's called" do
    tracer_adapter = class_double(
      'SyncMachine::TracerAdapters::NullAdapter'
    )
    expect(tracer_adapter).to \
      receive(:start_active_span).
      with('subject_ids_from_customer') { |&block|
        block.call
      }
    allow(SyncMachine::TracerAdapters).to \
      receive(:tracer_adapter).and_return(tracer_adapter)
    customer = create(:customer)
    enqueue_time_str = Time.now.iso8601
    OrderSync::FindSubjectsWorker.new.perform(
      'Customer', customer.id, ['name'], enqueue_time_str
    )
  end
end
