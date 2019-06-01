require 'spec_helper'
require 'active_support/core_ext/numeric/time'

RSpec.describe SyncMachine::EnsurePublication::Deduper do
  subject {
    described_class.new(
      job_class: job_class,
      last_job_finished_at: last_job_finished_at,
      subject_id: subject_id,
      enqueue_time_str: enqueue_time_str
    )
  }
  let(:enqueue_time_str) { Time.now.utc.to_s }
  let(:job_class) {
    double('job class', name: 'TestSync::EnsurePublicationWorker')
  }
  let(:redis_double) { double('Redis') }
  let(:redis_lock) { "TestSync::EnsurePublicationWorker:#{subject_id}" }
  let(:subject_id) { rand(1_000_000).to_s }

  before do
    allow(Redis).to receive(:current).and_return(redis_double)
  end

  describe "while running" do
    let(:last_job_finished_at) { }

    it "sets and then deletes a lock in Redis" do
      expect(redis_double).to receive(:set).with(
        redis_lock, "true", nx: true, ex: 10.minutes
      ).and_return(true)
      expect(redis_double).to receive(:del).with(redis_lock)
      yielded = false
      subject.dedupe { yielded = true }
      expect(yielded).to eq(true)
    end
  end

  describe "if the lock has been acquired by another Sidekiq thread" do
    let(:last_job_finished_at) { }

    it "re-queues the job for later" do
      expect(redis_double).to receive(:set).with(
        redis_lock, "true", nx: true, ex: 10.minutes
      ).and_return(false)
      expect(job_class).to \
        receive(:perform_in).with(anything, subject_id, enqueue_time_str)
      yielded = false
      subject.dedupe { yielded = true }
      expect(yielded).to eq(false)
    end
  end

  describe "if there's an exception when running the inner logic" do
    let(:last_job_finished_at) { }

    it "sets and then deletes a lock correctly anyway" do
      expect(redis_double).to receive(:set).with(
        redis_lock, "true", nx: true, ex: 10.minutes
      ).and_return(true)
      expect(redis_double).to receive(:del).with(redis_lock)
      expect {
        subject.dedupe { raise(StandardError) }
      }.to raise_error(StandardError)
    end
  end

  describe "if the previous payload was saved sometime after the enqueue time" do
    let(:enqueue_time_str) { (Time.now - 1.minute).utc.to_s }
    let(:last_job_finished_at) { Time.now.utc }

    it "considers this a duplicate job and does not continue" do
      expect(redis_double).to receive(:set).with(
        redis_lock, "true", nx: true, ex: 10.minutes
      ).and_return(true)
      expect(redis_double).to receive(:del).with(redis_lock)
      subject.dedupe { fail "Should not be called" }
    end
  end
end
