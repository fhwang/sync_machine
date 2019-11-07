module <%= class_name %>
  class Payload < ActiveRecord::Base
    self.table_name = "<%= singular_name %>_payloads"

    serialize :body

    validates :generated_at, presence: true
    validates :subject_id, presence: true, uniqueness: true
  end
end
