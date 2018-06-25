# frozen_string_literal: true

# RelationshipsRepository is a service class responsible for retrieval of
# relationships via the API
class RelationshipsRepository
  def self.search(security_token, client_ids)
    return [] if client_ids.blank?

    FerbAPI.make_api_call(
      security_token,
      FerbRoutes.relationships_path,
      :get,
      clientIds: client_ids
    ).body
  end

  def self.update(security_token, save_relationship)
    FerbAPI.make_api_call(
      security_token,
      FerbRoutes.save_relationship_path,
      :post,
      saveRelationship: save_relationship
    ).body
  end
end
