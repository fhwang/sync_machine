require 'sync_machine/tracer_adapters/open_tracing_adapter'

module SyncMachine
  # Adapt SyncMachine functionality to a specific distributed tracer.
  module TracerAdapters
    def self.tracer_adapter
      if const_defined?(:OpenTracing)
        OpenTracingAdapter
      else
        NullAdapter
      end
    end

    # Do not log spans anywhere.
    module NullAdapter
      def self.start_active_span(_name)
        yield
      end
    end
  end
end
