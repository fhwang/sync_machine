require 'spec_helper'

RSpec.describe SyncMachine::EnsurePublicationWorker do
  def perform
    OrderSync::EnsurePublicationWorker.new.perform(
      subject.id, Time.now.iso8601
    )
  end

  describe "if the subject is not publishable" do
    let(:subject) { create(:order, publishable: false) }

    it "does not send the payload" do
      expect(OrderSync::PostService).not_to receive(:post)
      perform
    end

    it "logs a span for every hook that's called" do
      tracer_adapter = class_double(
        'SyncMachine::TracerAdapters::NullAdapter'
      )
      expect(tracer_adapter).to \
        receive(:start_active_span).with('check_publishable')
      expect(tracer_adapter).not_to \
        receive(:start_active_span).with('build')
      expect(tracer_adapter).not_to \
        receive(:start_active_span).with('publish')
      expect(tracer_adapter).not_to \
        receive(:start_active_span).with('after_publish')
      allow(SyncMachine::TracerAdapters).to \
        receive(:tracer_adapter).and_return(tracer_adapter)
      perform
    end
  end

  describe "if a payload has never been sent" do
    let(:subject) {
      create(
        :order,
        publishable: true,
        next_payload: { 'abc' => 'def' }
      )
    }

    it "sends the payload" do
      expect(OrderSync::PostService).to receive(:post)
      perform
    end

    it "calls the after_publish block after sending the payload" do
      expect(OrderSync::PostService).to receive(:after_post)
      perform
    end

    it "logs a span for every hook that's called" do
      tracer_adapter = class_double(
        'SyncMachine::TracerAdapters::NullAdapter'
      )
      hook_names = %w(check_publishable build publish after_publish)
      hook_names.each do |hook_name|
        expect(tracer_adapter).to \
          receive(:start_active_span).with(hook_name) { |&block|
            block.call
          }
      end
      allow(SyncMachine::TracerAdapters).to \
        receive(:tracer_adapter).and_return(tracer_adapter)
      perform
    end
  end

  describe "if the same payload has previously been sent" do
    let(:payload) { { "abc" => "def" } }
    let(:subject) {
      create(:order, publishable: true, next_payload: payload)
    }

    before do
      OrderSync::Payload.create!(
        body: payload,
        generated_at: Time.now - 1.minute,
        subject_id: subject.id
      )
    end

    it "does not send the payload" do
      expect(OrderSync::PostService).not_to receive(:post)
      perform
    end

    it "does not call the after_publish hook" do
      expect(OrderSync::PostService).not_to receive(:after_post)
      perform
    end
  end

  describe "if a different payload has previously been sent" do
    let(:last_payload) { { "abc" => "def" } }
    let(:next_payload) { { "abc" => "123" } }
    let(:subject) {
      create(
        :order, publishable: true, next_payload: next_payload
      )
    }

    before do
      OrderSync::Payload.create!(
        body: last_payload,
        generated_at: Time.now - 1.minute,
        subject_id: subject.id
      )
    end

    it "sends the payload" do
      expect(OrderSync::PostService).to receive(:post)
      perform
    end
  end

  describe "if there is no check_publishable block" do
    it "always builds the payload" do
      expect(NoCheckPublishableSync::Builder).to \
        receive(:build).at_least(:once)
      NoCheckPublishableSync::EnsurePublicationWorker.new.perform(
        create(:order).id, Time.now.iso8601
      )
    end
  end
end
