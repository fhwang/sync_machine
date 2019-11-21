module SyncMachine
  # Initialize SyncMachine inside a Rails application.
  class Railtie < Rails::Railtie
    initializer :sync_machine do
      Module.const_defined?(:ActiveRecord) && \
        require("sync_machine/orm_adapters/active_record_adapter")
      Module.const_defined?(:Mongoid) && \
        require("sync_machine/orm_adapters/mongoid_adapter")
      if Module.const_defined?(:OpenTracing)
        begin
          require 'sidekiq-opentracing'
        rescue LoadError
          SyncMachine.abort_with_installation_hint(
            'sfx-sidekiq-opentracing', 'OpenTracing'
          )
        end
      end
    end

    config.after_initialize do
      if Module.const_defined?(:OpenTracing)
        Sidekiq::Tracer.instrument(tracer: OpenTracing.global_tracer)
      end
    end
  end
end
