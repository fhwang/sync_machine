require 'spec_helper'

RSpec.describe "SyncMachine::EnsurePublicationWorker for Mongoid" do
  def perform
    MongoidSync::EnsurePublicationWorker.new.perform(
      subject.id.to_s, Time.now.iso8601
    )
  end

  describe "if the same payload has previously been sent" do
    let(:payload) { { "abc" => "def" } }
    let(:subject) {
      create(:mongoid_order, publishable: true, next_payload: payload)
    }

    before do
      MongoidSync::Payload.create!(
        body: payload,
        generated_at: Time.now - 1.minute,
        subject_id: subject.id.to_s
      )
    end

    it "does not send the payload" do
      expect(MongoidSync::PostService).not_to receive(:post)
      perform
    end
  end
end
