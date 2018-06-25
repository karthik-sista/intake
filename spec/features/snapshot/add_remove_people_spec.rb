# frozen_string_literal: true

require 'rails_helper'
require 'feature/testing'

feature 'Adding and removing a person from a snapshot' do
  around do |example|
    Feature.run_with_activated(:release_two) do
      example.run
    end
  end

  let(:person) do
    {
      id: '1',
      legacy_descriptor: {
        legacy_id: '1',
        legacy_ui_id: '1',
      },
      first_name: 'Marge',
      gender: 'male',
      date_of_birth: '2001-09-11',
      phone_numbers: [{
        id: '1',
        type: 'Home',
        number: '9712876774'
      }],
      languages: %w[French Italian],
      addresses: [{
        id: '1',
        street_address: '123 C Street',
        city: 'City',
        state: 'CA',
        zip: '12345',
        type: 'Common'
      }]
    }
  end

  before do
    stub_system_codes
    stub_empty_history_for_clients [person[:legacy_descriptor][:legacy_id]]
    stub_request(
      :get,
      ferb_api_url(
        FerbRoutes.relationships_path
      ) + "?clientIds=#{person[:legacy_descriptor][:legacy_id]}"
    ).and_return(json_body([].to_json, status: 200))

    search_response = PersonSearchResponseBuilder.build do |response|
      response.with_total(1)
      response.with_hits do
        [
          PersonSearchResultBuilder.build do |builder|
            builder.with_first_name('Marge')
            builder.with_legacy_descriptor(person[:legacy_descriptor])
            builder.with_last_name(person[:last_name])
            builder.with_phone_number(person[:phone_numbers].first)
            builder.with_addresses do
              [
                AddressSearchResultBuilder.build do |address|
                  address.with_state_code(person[:addresses][0][:state])
                  address.with_city(person[:addresses][0][:city])
                  address.with_zip(person[:addresses][0][:zip])
                  address.with_type do
                    AddressTypeSearchResultBuilder.build('Home')
                  end
                  address.with_phone_number(person[:phone_numbers].first)
                end
              ]
            end
            builder.with_gender(person[:gender])
            builder.with_date_of_birth(person[:date_of_birth])
            builder.with_ssn(person[:ssn])
          end
        ]
      end
    end

    stub_person_search(search_term: 'Ma', person_response: search_response)
    stub_request(
      :get,
      ferb_api_url(FerbRoutes.client_authorization_path(person[:legacy_descriptor][:legacy_id]))
    ).and_return(json_body('', status: 200))
    stub_person_find(id: person[:legacy_descriptor][:legacy_id], person_response: search_response)
  end

  scenario 'User can add and remove users on snapshot' do
    visit snapshot_path

    within '#search-card', text: 'Search' do
      fill_in 'Search for clients', with: 'Ma'
    end

    within '#search-card', text: 'Search' do
      expect(page).not_to have_content 'Create a new person'
      page.find('strong', text: 'Marge').click
    end

    expect(
      a_request(
        :get, ferb_api_url(FerbRoutes.client_authorization_path(person[:legacy_descriptor][:legacy_id]))
      )
    ).to have_been_made

    within show_participant_card_selector(person[:legacy_descriptor][:legacy_id]) do
      within '.card-body' do
        expect(page).to have_content(person[:legacy_descriptor][:legacy_ui_id])
        expect(page).to have_content(person[:first_name])
        expect(page).to have_content(person[:last_name])
        expect(page).to have_content('(971) 287-6774')
        expect(page).to have_content(person[:phone_numbers].first[:type])
        expect(page).to have_content(person[:gender].capitalize)
        expect(page).to have_content(Date.parse(person[:date_of_birth]).strftime('%m/%d/%Y'))
        expect(page).to have_content(person[:ssn])
      end

      within '.card-header' do
        expect(page).not_to have_content 'Edit'
        expect(page).to_not have_content('Sensitive')
        expect(page).to have_content("#{person[:first_name]} #{person[:last_name]}")
        click_button 'Remove person'
      end
    end

    expect(
      a_request(
        :get,
        ferb_api_url(
          FerbRoutes.history_of_involvements_path
        ) + "?clientIds=#{person[:legacy_descriptor][:legacy_id]}"
      )
    ).to have_been_made.times(1)

    expect(
      a_request(
        :get,
        ferb_api_url(
          FerbRoutes.relationships_path
        ) + "?clientIds=#{person[:legacy_descriptor][:legacy_id]}"
      )
    ).to have_been_made.times(1)

    expect(page).not_to have_content show_participant_card_selector(person[:id])
    expect(page).not_to have_content(person[:first_name])
  end

  scenario 'Clicking Start Over removes people from the snapshot page' do
    visit snapshot_path

    within '#search-card', text: 'Search' do
      fill_in 'Search for clients', with: 'Ma'
    end

    within '#search-card', text: 'Search' do
      expect(page).not_to have_content 'Create a new person'
      page.find('strong', text: 'Marge').click
    end

    expect(
      a_request(
        :get, ferb_api_url(FerbRoutes.client_authorization_path(person[:legacy_descriptor][:legacy_id]))
      )
    ).to have_been_made

    within show_participant_card_selector(person[:legacy_descriptor][:legacy_id]) do
      within '.card-header' do
        expect(page).to have_content("#{person[:first_name]} #{person[:last_name]}")
      end
    end

    click_button 'Start Over'

    expect(page).not_to have_content(
      show_participant_card_selector(person[:legacy_descriptor][:legacy_id])
    )
    expect(page).not_to have_content(person[:first_name])
  end
end
