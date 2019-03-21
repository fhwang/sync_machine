require 'spec_helper'

RSpec.describe "SyncMachine::Payload" do
  it "has the right collection name" do
    expect(TestSync::Payload.collection.name).to eq('test_sync_payloads')
  end
end
