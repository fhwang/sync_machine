RSpec.describe SyncMachine do
  it "has a version number" do
    expect(SyncMachine::VERSION).not_to be nil
  end

  it "handles SyncMachine modules of arbitrary depth" do
    expect(SyncMachine.sync_module(TestSync::ChangeListener)).to eq(TestSync)
    expect(SyncMachine.sync_module(OuterNesting::NestedTestSync::ChangeListener)).to \
      eq(OuterNesting::NestedTestSync)
  end

  it "handles subjects with specified class names" do
    expect(ClassNameTestModule::Sync.subject_class).to \
      eq(ClassNameTestModule::Subject)
  end
end
