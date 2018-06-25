# frozen_string_literal: true

# Model for storing Intake person information.
class SaveRelationship
  include Virtus.model
  attribute :id, String
  attribute :client_id, String
  attribute :relative_id, String
  attribute :relationship_type
  attribute :absent_parent_indicator, Boolean
  attribute :same_home_status, Boolean
end
