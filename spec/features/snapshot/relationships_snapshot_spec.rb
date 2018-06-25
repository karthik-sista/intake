# frozen_string_literal: true

require 'rails_helper'
require 'feature/testing'

feature 'Snapshot relationship card' do
  before do
    stub_system_codes
  end

  context 'with no relationships' do
    around do |example|
      Feature.run_with_activated(:release_two) do
        example.run
      end
    end

    scenario 'snapshot displays the no relationships copy' do
      visit snapshot_path

      within '#relationships-card.card.show' do
        expect(page).to have_content('Search for people and add them to see their')
      end
    end
  end

  context 'load relationships' do
    around do |example|
      Feature.run_with_activated(:release_two) do
        example.run
      end
    end

    let(:participant) do
      {
        id: '1',
        first_name: 'Joe',
        last_name: 'Campbell',
        legacy_descriptor: {
          legacy_id: '1'
        }
      }
    end
    let(:relationships) do
      [
        {
          id: participant[:id].to_s,
          first_name: participant[:first_name],
          last_name: participant[:last_name],
          relationships: [{
            related_person_id: nil,
            related_person_legacy_id: '789',
            related_person_first_name: 'Jake',
            related_person_last_name: 'Campbell',
            relationship: 'Sister/Brother (Half)',
            related_person_relationship: '18',
            indexed_person_relationship: '277',
            relationship_context: 'Half'
          }, {
            related_person_id: nil,
            related_person_legacy_id: '156',
            related_person_first_name: 'Jane',
            related_person_last_name: 'Campbell',
            relationship: 'Sister/Sister (Half)',
            related_person_relationship: '280',
            indexed_person_relationship: '280',
            relationship_context: 'Half'
          }]
        }
      ]
    end

    before do
      stub_empty_history_for_clients([participant[:legacy_descriptor][:legacy_id]])

      search_response = PersonSearchResponseBuilder.build do |response|
        response.with_total(1)
        response.with_hits do
          [
            PersonSearchResultBuilder.build do |builder|
              builder.with_first_name('Marge')
              builder.with_legacy_descriptor(participant[:legacy_descriptor])
            end
          ]
        end
      end

      stub_person_search(search_term: 'Ma', person_response: search_response)
      stub_request(
        :get,
        ferb_api_url(FerbRoutes.client_authorization_path(participant[:legacy_descriptor][:legacy_id]))
      ).and_return(json_body('', status: 200))
      stub_person_find(
        id: participant[:legacy_descriptor][:legacy_id],
        person_response: search_response
      )

      stub_request(
        :get,
        ferb_api_url(
          FerbRoutes.relationships_path
        ) + "?clientIds=#{participant[:legacy_descriptor][:legacy_id]}"
      ).and_return(json_body(relationships.to_json, status: 200))

      visit snapshot_path

      within '#search-card', text: 'Search' do
        fill_in 'Search for clients', with: 'Ma'
      end

      within '#search-card', text: 'Search' do
        page.find('strong', text: 'Marge').click
      end
    end

    scenario 'should return the correct relationships' do
      expect(
        a_request(
          :get,
          ferb_api_url(
            FerbRoutes.relationships_path
          ) + "?clientIds=#{participant[:legacy_descriptor][:legacy_id]}"
        )
      ).to have_been_made

      within '#relationships-card.card.show', text: 'Relationships' do
        expect(page).to have_content(
          "#{relationships.first[:first_name]} #{relationships.first[:last_name]} is the.."
        )
        expect(page).to have_content('Sister (Half) of Jake Campbell')
        expect(page).to have_content('Sister (Half) of Jane Campbell')
      end
    end

    scenario 'clicking the Start Over button clears relationships card' do
      within '#relationships-card.card.show' do
        expect(page).to have_content(
          "#{relationships.first[:first_name]} #{relationships.first[:last_name]} is the.."
        )
      end

      click_button 'Start Over'

      within '#relationships-card.card.show' do
        expect(page).to have_content('Search for people and add them to see their relationships')
      end
    end
  end
end
