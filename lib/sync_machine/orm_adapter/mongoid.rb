module SyncMachine
  module OrmAdapter
    module Mongoid
      def self.setup
        require "mongoid"
        require "wisper/mongoid"
        Wisper::Mongoid.extend_all
      end

      def self.change_listener_changed_keys(record)
        record.changes.keys
      end

      def self.record_id_for_job(record_id)
        record_id.to_s
      end
    end
  end
end
