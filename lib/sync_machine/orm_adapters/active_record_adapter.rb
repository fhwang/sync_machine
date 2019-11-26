begin
  require 'wisper/activerecord'
rescue LoadError
  SyncMachine.abort_with_installation_hint(
    'wisper-activerecord', 'ActiveRecord'
  )
end

module SyncMachine
  module OrmAdapters
    # Adapt generic SyncMachine functionality to ActiveRecord.
    module ActiveRecordAdapter
      def self.change_listener_changed_keys(record)
        record.previous_changes.keys
      end

      def self.record_id_for_job(record_id)
        record_id
      end

      def self.sufficient_changes_to_find_subjects?(record)
        change_listener_changed_keys(record).present?
      end
    end
  end
end

Wisper::ActiveRecord.extend_all
