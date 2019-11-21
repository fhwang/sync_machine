module SyncMachine
  # Initialize SyncMachine inside a Rails application.
  class Railtie < Rails::Railtie
    initializer :sync_machine do
      Module.const_defined?(:ActiveRecord) && \
        require("sync_machine/orm_adapters/active_record_adapter")
      Module.const_defined?(:Mongoid) && \
        require("sync_machine/orm_adapters/mongoid_adapter")
    end
  end
end
