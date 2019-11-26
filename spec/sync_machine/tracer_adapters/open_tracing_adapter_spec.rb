require 'spec_helper'

RSpec.describe SyncMachine::TracerAdapters::OpenTracingAdapter do
  let(:active_span) { double('active_span') }
  let(:active_span_scope) { double('active_span_scope', span: active_span) }
  let(:exception_class) { Class.new(StandardError) }
  let(:span_name) { 'span_name' }
  let(:tracer) { double('tracer') }

  before do
    allow(OpenTracing).to receive(:global_tracer).and_return(tracer)
    allow(OpenTracing).to \
      receive(:active_span).and_return(double('parent_span', context: true))
  end

  describe "when the block runs successfully" do
    it "starts and closes an active span, and does not log error metadata" do
      expect(tracer).to \
        receive(:start_active_span).and_return(active_span_scope)
      expect(active_span_scope).to receive(:close)
      expect(active_span).not_to receive(:set_tag)
      expect(active_span).not_to receive(:log_kv)
      described_class.start_active_span(span_name) { }
    end
  end

  describe "when the block has a failure" do
    it "starts and closes an active span, and logs error metadata" do
      expect(tracer).to \
        receive(:start_active_span).and_return(active_span_scope)
      expect(active_span_scope).to receive(:close)
      expect(active_span).to receive(:set_tag)
      expect(active_span).to receive(:log_kv)
      expect {
        described_class.start_active_span(span_name) { raise(exception_class) }
      }.to raise_error(exception_class)
    end
  end
end
