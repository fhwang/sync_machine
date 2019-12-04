require 'spec_helper'

RSpec.describe SyncMachine::ChangeListener do
  describe "when the ORM is ActiveRecord" do
    before do
      OrderSync::FindSubjectsWorker.clear
    end

    describe "when a record is created" do
      it "enqueues a FindSubjectsWorker" do
        subject = Customer.create!
        expect(OrderSync::FindSubjectsWorker.jobs.count).to eq(1)
        args = OrderSync::FindSubjectsWorker.jobs.first['args']
        expect(args.size).to eq(4)
        expect(args[0]).to eq('Customer')
        expect(args[1]).to eq(subject.id)
        expect(args[2]).to eq(['id'])
        expect(Time.parse(args[3])).to be_within(1).of(Time.now)
      end
    end

    describe "after a record has been updated" do
      before do
        @test_sync_subject = Customer.create!
        OrderSync::FindSubjectsWorker.clear
        @test_sync_subject.name = "new name"
        @test_sync_subject.save!
        expect(OrderSync::FindSubjectsWorker.jobs.count).to eq(1)
        @args = OrderSync::FindSubjectsWorker.jobs.first['args']
      end

      it "includes changed keys" do
        expect(@args.size).to eq(4)
        expect(@args[0]).to eq('Customer')
        expect(@args[1]).to eq(@test_sync_subject.id)
        expect(@args[2]).to eq(['name'])
        expect(Time.parse(@args[3])).to be_within(1).of(Time.now)
      end

      it "enqueues with an enqueue_time with millisecond precision" do
        enqueue_time_str = @args[3]
        enqueue_time = Time.parse(enqueue_time_str)
        expect(enqueue_time.to_f > enqueue_time.to_i).to eq(true)
      end
    end
  end

  describe "when the ORM is Mongoid" do
    describe "when a record is created" do
      it "enqueues a FindSubjectsWorker with the ID as a string" do
        subject = MongoidCustomer.create!
        expect(MongoidSync::FindSubjectsWorker.jobs.count).to eq(1)
        args = MongoidSync::FindSubjectsWorker.jobs.first['args']
        expect(args[1]).to eq(subject.id.to_s)
      end
    end

    describe "when values within an embed are changed" do
      before do
        @mongoid_customer = MongoidCustomer.create!(
          mongoid_address: MongoidAddress.new(address1: '123 Main Street')
        )
        MongoidSync::FindSubjectsWorker.clear
        @mongoid_customer.mongoid_address.address2 = 'Apt 45'
        @mongoid_customer.save!
      end

      it "enqueues a FindSubjectsWorker" do
        expect(MongoidSync::FindSubjectsWorker.jobs.count).to eq(1)
        args = MongoidSync::FindSubjectsWorker.jobs.first['args']
        expect(args.size).to eq(4)
        expect(args[0]).to eq('MongoidCustomer')
        expect(args[1]).to eq(@mongoid_customer.id.to_s)
        expect(args[2]).to eq([])
        expect(Time.parse(args[3])).to be_within(1).of(Time.now)
      end
    end
  end
end
