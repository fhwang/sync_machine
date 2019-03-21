require 'spec_helper'

RSpec.describe SyncMachine::EnsurePublicationWorker do
  def perform
    TestSync::EnsurePublicationWorker.new.perform(
      subject.id.to_s, Time.now.iso8601
    )
  end

  describe "if the subject is not publishable" do
    let(:subject) { create(:order, publishable: false) }

    it "does not send the payload" do
      expect(TestSync::PostService).not_to receive(:post)
      perform
    end
  end

  describe "if a payload has never been sent" do
    let(:subject) { create(:order, publishable: true) }

    it "sends the payload" do
      expect(TestSync::PostService).to receive(:post)
      perform
    end

    it "is calls the after_publish block after sending the payload" do
      expect(TestSync::PostService).to receive(:after_post)
      perform
    end
  end

  describe "if the same payload has previously been sent" do
    let(:payload) { { "abc" => "def" } }
    let(:subject) { create(:order, publishable: true, next_payload: payload) }

    before do
      TestSync::Payload.create!(
        body: payload, generated_at: Time.now, subject_id: subject.id.to_s
      )
    end

    it "does not send the payload" do
      expect(TestSync::PostService).not_to receive(:post)
      perform
    end
  end

  describe "if a different payload has previously been sent" do
    let(:last_payload) { { "abc" => "def" } }
    let(:next_payload) { { "abc" => "123" } }
    let(:subject) {
      create(:order, publishable: true, next_payload: next_payload)
    }

    before do
      TestSync::Payload.create!(
        body: last_payload,
        generated_at: Time.now - 1.minute,
        subject_id: subject.id.to_s
      )
    end

    it "sends the payload" do
      expect(TestSync::PostService).to receive(:post)
      perform
    end
  end
end
