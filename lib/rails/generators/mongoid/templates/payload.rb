module <%= class_name %>
  class Payload
    include ::Mongoid::Document

    field :body, type: Hash
    field :generated_at, type: Time
    field :subject_id, type: String

    validates :generated_at, presence: true
    validates :subject_id, presence: true, uniqueness: true
  end
end
