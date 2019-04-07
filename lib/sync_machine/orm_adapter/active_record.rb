module SyncMachine
  module OrmAdapter
    # Adapt SyncMachine for use with ActiveRecord-based applications.
    module ActiveRecord
      def self.setup
        require "active_record"
        require "wisper/active_record"
        Wisper::ActiveRecord.extend_all
      end

      def self.change_listener_changed_keys(record)
        record.previous_changes.keys
      end

      def self.record_id_for_job(record_id)
        record_id
      end
    end
  end
end
