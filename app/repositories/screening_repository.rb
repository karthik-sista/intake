# frozen_string_literal: true

# ScreeningRepository is a service class responsible for creation of a screening
# resource via the API
class ScreeningRepository
  def self.create(security_token, screening)
    response = FerbAPI.make_api_call(
      security_token,
      FerbRoutes.screenings_path,
      :post,
      screening.as_json(except: 'id')
    )
    response.body.to_json
  end

  def self.find(security_token, id)
    response = IntakeAPI.make_api_call(
      security_token,
      ExternalRoutes.intake_api_screening_path(id),
      :get
    )
    Screening.new(response.body)
  end

  def self.update(security_token, screening)
    raise 'Error updating screening: id is required' unless screening.id
    response = IntakeAPI.make_api_call(
      security_token,
      ExternalRoutes.intake_api_screening_path(screening.id),
      :put,
      screening.as_json.except('id')
    )
    Screening.new(response.body)
  end

  def self.search(security_token)
    response = FerbAPI.make_api_call(
      security_token,
      FerbRoutes.screenings_path,
      :get
    )
    response.body.to_json
  end

  def self.history_of_involvements(security_token, id)
    if Feature.active?(:hoi_from_intake_api)
      api = IntakeAPI
      path = ExternalRoutes.intake_api_history_of_involvements_path(id)
    else
      api = FerbAPI
      path = FerbRoutes.screening_history_of_involvements_path(id)
    end
    response = api.make_api_call(security_token, path, :get)
    response.body
  end

  def self.submit(security_token, id)
    response = IntakeAPI.make_api_call(
      security_token,
      ExternalRoutes.intake_api_screening_submit_path(id),
      :post
    )
    Screening.new(response.body)
  end
end
