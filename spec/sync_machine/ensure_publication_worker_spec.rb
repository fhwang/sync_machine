require 'spec_helper'

RSpec.describe SyncMachine::EnsurePublicationWorker do
  def perform_for_active_record
    TestActiveRecordSync::EnsurePublicationWorker.new.perform(
      subject.id.to_s, Time.now.iso8601
    )
  end

  def perform_for_mongoid
    TestMongoidSync::EnsurePublicationWorker.new.perform(
      subject.id.to_s, Time.now.iso8601
    )
  end

  describe 'for an ActiveRecord-based application' do
    before do
      setup_active_record
    end

    describe "if the subject is not publishable" do
      let(:subject) { create(:active_record_order, publishable: false) }

      it "does not send the payload" do
        expect(TestActiveRecordSync::PostService).not_to receive(:post)
        perform_for_active_record
      end
    end

    describe "if a payload has never been sent" do
      let(:subject) { create(:active_record_order, publishable: true) }

      it "sends the payload" do
        expect(TestActiveRecordSync::PostService).to receive(:post)
        perform_for_active_record
      end

      it "calls the after_publish block after sending the payload" do
        expect(TestActiveRecordSync::PostService).to receive(:after_post)
        perform_for_active_record
      end
    end

    describe "if the same payload has previously been sent" do
      let(:payload) { { "abc" => "def" } }
      let(:subject) {
        create(:active_record_order, publishable: true, next_payload: payload)
      }

      before do
        TestActiveRecordSync::Payload.create!(
          body: payload, generated_at: Time.now, subject_id: subject.id.to_s
        )
      end

      it "does not send the payload" do
        expect(TestActiveRecordSync::PostService).not_to receive(:post)
        perform_for_active_record
      end
    end
  end

  describe 'for a Mongoid-based application' do
    before do
      setup_mongoid
    end

    describe "if the subject is not publishable" do
      let(:subject) { create(:mongoid_order, publishable: false) }

      it "does not send the payload" do
        expect(TestMongoidSync::PostService).not_to receive(:post)
        perform_for_mongoid
      end
    end

    describe "if a payload has never been sent" do
      let(:subject) { create(:mongoid_order, publishable: true) }

      it "sends the payload" do
        expect(TestMongoidSync::PostService).to receive(:post)
        perform_for_mongoid
      end

      it "calls the after_publish block after sending the payload" do
        expect(TestMongoidSync::PostService).to receive(:after_post)
        perform_for_mongoid
      end
    end

    describe "if the same payload has previously been sent" do
      let(:payload) { { "abc" => "def" } }
      let(:subject) {
        create(:mongoid_order, publishable: true, next_payload: payload)
      }

      before do
        TestMongoidSync::Payload.create!(
          body: payload, generated_at: Time.now, subject_id: subject.id.to_s
        )
      end

      it "does not send the payload" do
        expect(TestMongoidSync::PostService).not_to receive(:post)
        perform_for_mongoid
      end
    end

    describe "if a different payload has previously been sent" do
      let(:last_payload) { { "abc" => "def" } }
      let(:next_payload) { { "abc" => "123" } }
      let(:subject) {
        create(:mongoid_order, publishable: true, next_payload: next_payload)
      }

      before do
        TestMongoidSync::Payload.create!(
          body: last_payload,
          generated_at: Time.now - 1.minute,
          subject_id: subject.id.to_s
        )
      end

      it "sends the payload" do
        expect(TestMongoidSync::PostService).to receive(:post)
        perform_for_mongoid
      end
    end
  end
end
