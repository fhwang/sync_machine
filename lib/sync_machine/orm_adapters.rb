module SyncMachine
  # Adapt generic SyncMachine functionality to a specific ORM.
  module OrmAdapters
    def self.orm_adapter(sync_module)
      subject_class = sync_module.subject_class
      if const_defined?(:ActiveRecordAdapter) &&
         subject_class < ActiveRecord::Base
        ActiveRecordAdapter
      elsif const_defined?(:MongoidAdapter) &&
            subject_class.included_modules.include?(Mongoid::Document)
        MongoidAdapter
      end
    end
  end
end
