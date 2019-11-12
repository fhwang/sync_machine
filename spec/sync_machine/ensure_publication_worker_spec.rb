require 'spec_helper'

RSpec.describe SyncMachine::EnsurePublicationWorker do
  describe "when the ORM is ActiveRecord" do
    def perform
      ActiveRecordOrderSync::EnsurePublicationWorker.new.perform(
        subject.id, Time.now.iso8601
      )
    end

    describe "if the subject is not publishable" do
      let(:subject) { create(:active_record_order, publishable: false) }

      it "does not send the payload" do
        expect(ActiveRecordOrderSync::PostService).not_to receive(:post)
        perform
      end
    end

    describe "if a payload has never been sent" do
      let(:subject) { create(:active_record_order, publishable: true) }

      it "sends the payload" do
        expect(ActiveRecordOrderSync::PostService).to receive(:post)
        perform
      end

      it "calls the after_publish block after sending the payload" do
        expect(ActiveRecordOrderSync::PostService).to receive(:after_post)
        perform
      end
    end

    describe "if the same payload has previously been sent" do
      let(:payload) { { "abc" => "def" } }
      let(:subject) {
        create(:active_record_order, publishable: true, next_payload: payload)
      }

      before do
        ActiveRecordOrderSync::Payload.create!(
          body: payload,
          generated_at: Time.now - 1.minute,
          subject_id: subject.id
        )
      end

      it "does not send the payload" do
        expect(ActiveRecordOrderSync::PostService).not_to receive(:post)
        perform
      end

      it "does not call the after_publish hook" do
        expect(ActiveRecordOrderSync::PostService).not_to receive(:after_post)
        perform
      end
    end

    describe "if a different payload has previously been sent" do
      let(:last_payload) { { "abc" => "def" } }
      let(:next_payload) { { "abc" => "123" } }
      let(:subject) {
        create(
          :active_record_order, publishable: true, next_payload: next_payload
        )
      }

      before do
        ActiveRecordOrderSync::Payload.create!(
          body: last_payload,
          generated_at: Time.now - 1.minute,
          subject_id: subject.id
        )
      end

      it "sends the payload" do
        expect(ActiveRecordOrderSync::PostService).to receive(:post)
        perform
      end
    end
  end

  describe "when the ORM is Mongoid" do
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
end
