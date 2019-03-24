require 'spec_helper'

RSpec.describe "SyncMachine::EnsurePublicationWorker deduping" do
  let(:enqueue_time_str) { Time.now.utc.to_s }
  let(:order) { Order.new(id: subject_id) }
  let(:redis_double) { double('Redis') }
  let(:redis_lock) { "TestSync::EnsurePublicationWorker:#{subject_id}" }
  let(:subject_id) { rand(1_000_000).to_s }

  before do
    allow(Redis).to receive(:current).and_return(redis_double)
    allow(Order).to \
      receive(:find).with(subject_id).and_return(order)
  end

  describe "while running" do
    it "sets and then deletes a lock in Redis" do
      expect(redis_double).to receive(:set).with(
        redis_lock, "true", nx: true, ex: 10.minutes
      ).and_return(true)
      expect(redis_double).to receive(:del).with(redis_lock)
      TestSync::EnsurePublicationWorker.new.perform(
        subject_id, enqueue_time_str
      )
    end
  end

  describe "if the lock has been acquired by another Sidekiq thread" do
    it "re-queues the job for later" do
      expect(redis_double).to receive(:set).with(
        redis_lock, "true", nx: true, ex: 10.minutes
      ).and_return(false)
      expect(TestSync::EnsurePublicationWorker).to \
        receive(:perform_in).with(anything, subject_id, enqueue_time_str)
      TestSync::EnsurePublicationWorker.new.perform(
        subject_id, enqueue_time_str
      )
    end
  end

  describe "if there's an exception when running the inner logic" do
    it "sets and then deletes a lock correctly anyway" do
      expect(redis_double).to receive(:set).with(
        redis_lock, "true", nx: true, ex: 10.minutes
      ).and_return(true)
      expect(redis_double).to receive(:del).with(redis_lock)
      allow(TestSync::PostService).to receive(:post).and_raise(StandardError)
      expect {
        TestSync::EnsurePublicationWorker.new.perform(
          subject_id, enqueue_time_str
        )
      }.to raise_error(StandardError)
    end
  end

  describe "if the previous payload was saved sometime after the enqueue time" do
    let(:enqueue_time_str) { (Time.now - 1.minute).utc.to_s }

    it "considers this a duplicate job and does not continue" do
      expect(redis_double).to receive(:set).with(
        redis_lock, "true", nx: true, ex: 10.minutes
      ).and_return(true)
      expect(redis_double).to receive(:del).with(redis_lock)
      TestSync::Payload.create!(
        body: order.next_payload,
        generated_at: Time.now,
        subject_id: subject_id
      )
      expect(TestSync::PostService).not_to receive(:post)
      TestSync::EnsurePublicationWorker.new.perform(
        subject_id, enqueue_time_str
      )
    end
  end
end
