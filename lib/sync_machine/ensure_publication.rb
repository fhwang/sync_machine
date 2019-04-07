module SyncMachine
  # Orchestrate logic around a change notification and whether to publish a new
  # document to the service.
  class EnsurePublication
    def initialize(enqueue_time_str:, hooks:, subject:, sync_module:)
      @enqueue_time_str = enqueue_time_str
      @hooks = hooks
      @subject = subject
      @sync_module = sync_module
    end

    def run
      dedupe { run_deduped }
    end

    private

    def call_after_publish
      return unless (after_publish_hook = hook(:after_publish))
      after_publish_hook.call(@subject)
    end

    def dedupe
      deduper = Deduper.new(
        job_class: @sync_module.const_get('EnsurePublicationWorker'),
        last_job_finished_at: publication_history.last_job_finished_at,
        subject_id: subject_id,
        enqueue_time_str: @enqueue_time_str
      )
      deduper.dedupe { yield }
    end

    def hook(hook_sym)
      @hooks[hook_sym]
    end

    def payload_body
      @payload_body ||= hook(:build).call(@subject)
    end

    def publication_history
      @publication_history ||= PublicationHistory.new(
        subject_id: subject_id, sync_module: @sync_module
      )
    end

    def run_deduped
      return unless hook(:check_publishable).call(@subject)
      if publication_history.last_publish_equals?(payload_body)
        publication_history.record_generation_time
      else
        hook(:publish).call(@subject, payload_body)
        publication_history.update(payload_body)
      end
      call_after_publish
    end

    def subject_id
      SyncMachine.orm_adapter.record_id_for_job(@subject.id)
    end
  end
end
