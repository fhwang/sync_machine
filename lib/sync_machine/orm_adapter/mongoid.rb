module SyncMachine
  module OrmAdapter
    module Mongoid
      def self.setup
        require "mongoid"
        require "wisper/mongoid"
        Wisper::Mongoid.extend_all
      end

      def self.change_listener_changed_keys(record)
        changed_keys = record.changes.keys
        record.class.reflect_on_all_associations.each do |assoc|
          if assoc.macro == :embeds_one && record.send(assoc.name).try(:changed?)
            changed_keys << assoc.name
          end
        end
        changed_keys
      end

      def self.record_id_for_job(record_id)
        record_id.to_s
      end
    end
  end
end
