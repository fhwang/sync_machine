RSpec.describe SyncMachine do
  it "has a version number" do
    expect(SyncMachine::VERSION).not_to be nil
  end

  it "handles SyncMachine modules of arbitrary depth" do
    expect(SyncMachine.sync_module(OrderSync::ChangeListener)).to \
      eq(OrderSync)
    expect(SyncMachine.sync_module(OuterNesting::NestedSync::ChangeListener)).to \
      eq(OuterNesting::NestedSync)
  end

  it "handles subjects with specified class names" do
    expect(ClassNameTestModule::Sync.subject_class).to \
      eq(ClassNameTestModule::Subject)
  end
end
