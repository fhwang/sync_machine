begin
  require 'wisper/mongoid'
rescue LoadError
  SyncMachine.abort_with_installation_hint('fhwang-wisper-mongoid', 'Mongoid')
end

module SyncMachine
  module OrmAdapters
    # Adapt generic SyncMachine functionality to Mongoid.
    module MongoidAdapter
      def self.change_listener_changed_keys(record)
        record.changes.keys
      end

      def self.record_id_for_job(record_id)
        record_id.to_s
      end

      def self.sufficient_changes_to_find_subjects?(_record)
        true
      end
    end
  end
end

Wisper::Mongoid.extend_all
