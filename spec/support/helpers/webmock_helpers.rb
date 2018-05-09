# frozen_string_literal: true

module WebmockHelpers
  LOW_BOOST = 2
  NO_BOOST = 1
  def stub_screening_put_request_with_anything_and_return(
    screening,
    with_updated_attributes: {}
  )
    api_response = screening.merge(with_updated_attributes)
    api_response.delete(:incident_address)
    stub_request(:put, intake_api_url(ExternalRoutes.intake_api_screening_path(screening[:id])))
      .and_return(json_body(api_response.to_json))
  end

  def stub_person_find(id:, person_response:)
    request_path = dora_api_url(ExternalRoutes.dora_people_light_index_path)
    request_payload = {
      'body' => {
        'query' => {
          'bool' => {
            'must' => [{ 'match' => { 'id' => id } }]
          }
        },
        '_source' => anything
      }
    }
    response_payload = json_body(person_response.to_json, status: 200)
    stub_request(:post, request_path).with(request_payload).to_return(response_payload)
  end

  def stub_person_search(search_term:, person_response:, search_after: nil)
    request_path = dora_api_url(ExternalRoutes.dora_people_light_index_path)
    request_payload = {
      'body' => {
        'size' => 25,
        'track_scores' => true,
        'sort' => [{ '_score' => 'desc', '_uid' => 'desc' }],
        'query' => {
          'bool' => {
            'must' => [
              {
                'bool' => {
                  'should' => [
                    {
                      'match': {
                        'autocomplete_search_bar' => {
                          'query' => search_term.downcase,
                          'fuzziness' => 'AUTO',
                          'operator' => 'and',
                          'boost' => LOW_BOOST
                        }
                      }
                    },
                    {
                      'match' => {
                        'autocomplete_search_bar.diminutive' => {
                          'query' => search_term.downcase,
                          'operator' =>  'and',
                          'boost' => NO_BOOST
                        }
                      }
                    },
                    {
                      'match' =>  {
                        'autocomplete_search_bar.phonetic' => {
                          query: search_term.downcase,
                          'operator' =>  'and',
                          'boost' => NO_BOOST
                        }
                      }
                    }
                  ]
                }

              }

            ],

            'should' => anything
          }
        },
        '_source' => anything,
        'highlight' => anything
      }
    }
    request_payload['body'][:search_after] = search_after unless search_after.nil?
    response_payload = json_body(person_response.to_json, status: 200)
    stub_request(:post, request_path).with(request_payload).to_return(response_payload)
  end

  def as_json_without_root_id(model)
    model.as_json.except('id')
  end

  def json_body(json, options = {})
    { body: json, headers: { 'Content-Type' => 'application/json' } }.merge(options)
  end

  def intake_api_url(path)
    base_path = Rails.application.config.intake[:api_url].sub(%r{/$}, '')
    specific_path = path.sub(%r{^/}, '')
    "#{base_path}/#{specific_path}"
  end

  def ferb_api_url(path)
    "#{Rails.application.config.intake[:ferb_api_url]}#{path}"
  end

  def dora_api_url(path)
    "#{Rails.application.config.intake[:dora_api_url]}#{path}"
  end
end

RSpec.configure do |config|
  config.include WebmockHelpers
end
