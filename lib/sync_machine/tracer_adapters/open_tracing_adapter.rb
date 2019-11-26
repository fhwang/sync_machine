module SyncMachine
  module TracerAdapters
    # Adapt OpenTracing for use with SyncMachine.
    module OpenTracingAdapter
      def self.start_active_span(name, &block)
        scope = tracer.start_active_span(
          name,
          child_of: parent_span.context,
          tags: tags
        )
        block.call
      rescue Exception => exception
        log_errors(scope.span, exception) if scope
        raise exception
      ensure
        scope.close if scope
      end

      def self.log_errors(span, exception)
        span.set_tag('error', true)
        span.log_kv(event: 'error', :'error.object' => exception)
      end

      def self.parent_span
        OpenTracing.active_span
      end

      def self.tags
        { 'component' => 'SyncMachine', 'span.kind' => 'server' }
      end

      def self.tracer
        OpenTracing.global_tracer
      end
    end
  end
end
