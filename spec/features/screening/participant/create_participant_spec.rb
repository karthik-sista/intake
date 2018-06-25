# frozen_string_literal: true

require 'rails_helper'
require 'feature/testing'

def filtered_participant_attributes
  %i[
    date_of_birth
    first_name
    gender
    last_name
    ssn
    sealed
    sensitive
  ]
end

feature 'Create participant' do
  let(:existing_participant) do
    {
      id: '1',
      first_name: 'first',
      last_name: 'last',
      addresses: [],
      languages: [],
      phone_numbers: [],
      roles: []
    }
  end
  let(:existing_screening) do
    {
      id: '1',
      incident_address: {},
      cross_reports: [],
      allegations: [],
      safety_alerts: [],
      participants: [existing_participant]
    }
  end
  let(:marge_date_of_birth) { 15.years.ago.to_date }
  let(:homer_date_of_birth) { 16.years.ago.to_date }
  let(:marge_address) do
    {
      id: '1',
      legacy_descriptor: {
        legacy_id: '2a'
      },
      street_address: '123 Fake St',
      city: 'Springfield',
      state: 'NY',
      zip: '12345',
      type: 'Home'
    }
  end
  let(:marge_phone_number) do
    {
      id: '1',
      number: '9712876774',
      type: 'Home'
    }
  end

  let(:marge) do
    {
      id: '4',
      date_of_birth: marge_date_of_birth.to_s(:db),
      first_name: 'Marge',
      gender: 'female',
      last_name: 'Simpson',
      ssn: '123-23-1234',
      sealed: false,
      sensitive: true,
      languages: %w[French Italian],
      roles: [],
      legacy_descriptor: {
        legacy_id: '1',
        legacy_source_table: 'CLIENT_T',
      },
      addresses: [marge_address],
      phone_numbers: [marge_phone_number],
      races: [
        { race: 'White', race_detail: 'European' },
        { race: 'American Indian or Alaska Native', race_detail: 'Alaska Native' }
      ],
      ethnicity: { hispanic_latino_origin: 'Yes', ethnicity_detail: ['Central American'] }
    }
  end
  let(:homer) do
    {
      id: '2',
      legacy_descriptor: {
        legacy_id: '1',
        legacy_source_table: 'CLIENT_T'
      },
      date_of_birth: homer_date_of_birth.to_s(:db),
      first_name: 'Homer',
      gender: 'male',
      last_name: 'Simpson',
      ssn: '123-23-1234',
      sealed: false,
      sensitive: false,
      languages: %w[French Italian],
      addresses: [marge_address],
      phone_numbers: [marge_phone_number],
      roles: [],
      races: [
        { race: 'Asian', race_detail: 'Other Asian' },
        { race: 'White' },
        { race: 'White', race_detail: 'Romanian' },
        { race: 'Asian', race_detail: 'Hmong' },
        { race: 'Asian', race_detail: 'Chinese' },
        { race: 'American Indian or Alaska Native', race_detail: 'Alaska Native' }
      ],
      ethnicity: { hispanic_latino_origin: 'Yes', ethnicity_detail: %w[Hispanic Mexican] }
    }
  end

  let(:marge_response) do
    PersonSearchResponseBuilder.build do |response|
      response.with_total(1)
      response.with_hits do
        [
          PersonSearchResultBuilder.build do |builder|
            builder.with_first_name('Marge')
            builder.with_last_name('Simpson')
            builder.with_legacy_descriptor(marge[:legacy_descriptor])
            builder.with_sensitivity
          end
        ]
      end
    end
  end

  let(:homer_response) do
    PersonSearchResponseBuilder.build do |response|
      response.with_total(1)
      response.with_hits do
        [
          PersonSearchResultBuilder.build do |builder|
            builder.with_first_name('Homer')
            builder.with_last_name('Simpson')
            builder.with_legacy_descriptor(homer[:legacy_descriptor])
          end
        ]
      end
    end
  end

  before do
    stub_request(
      :get, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_county_agencies('c40')
    %w[ma mar marg marge marge\ simpson].each do |search_text|
      stub_person_search(search_term: search_text, person_response: marge_response)
    end
    %w[ho hom home homer].each do |search_text|
      stub_person_search(search_term: search_text, person_response: homer_response)
    end
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)
  end

  scenario 'creating an unknown participant' do
    visit edit_screening_path(id: existing_screening[:id])
    created_participant_unknown = {
      id: '2',
      screening_id: existing_screening[:id],
      roles: [],
      addresses: [],
      languages: [],
      phone_numbers: []
    }

    stub_request(:post,
      ferb_api_url(FerbRoutes.screening_participant_path(existing_screening[:id])))
      .and_return(json_body(created_participant_unknown.to_json, status: 201))

    within '#search-card', text: 'Search' do
      fill_in 'Search for any person', with: 'Marge'
      click_button 'Create a new person'
      expect(page).to_not have_button('Create a new person')
    end
    expect(a_request(:post,
      ferb_api_url(FerbRoutes.screening_participant_path(existing_screening[:id]))))
      .to have_been_made

    within edit_participant_card_selector(created_participant_unknown[:id]) do
      within '.card-header' do
        expect(page).to_not have_content('Sensitive')
        expect(page).to have_content 'Unknown Person'
      end
    end
  end

  scenario 'create and edit an unknown participant' do
    visit edit_screening_path(id: existing_screening[:id])
    created_participant_unknown = {
      id: '3',
      screening_id: existing_screening[:id],
      roles: [],
      addresses: [],
      languages: [],
      phone_numbers: []
    }

    stub_request(:post,
      ferb_api_url(FerbRoutes.screening_participant_path(existing_screening[:id])))
      .and_return(json_body(created_participant_unknown.to_json, status: 201))

    within '#search-card', text: 'Search' do
      fill_in 'Search for any person', with: 'Marge'
      click_button 'Create a new person'
      expect(page).to_not have_button('Create a new person')
    end

    expect(a_request(:post,
      ferb_api_url(FerbRoutes.screening_participant_path(existing_screening[:id]))))
      .to have_been_made

    within edit_participant_card_selector(created_participant_unknown[:id]) do
      fill_in 'First Name', with: 'Filled In First Name'
      expect(find_field('First Name').value).to eq('Filled In First Name')
    end
  end

  scenario 'API returns a 403 response when trying to add a person' do
    if ENV.key?('TEST_ENV_NUMBER')
      skip 'Pending this test as it just fails on jenkins when the js alert is triggered'
    end

    visit edit_screening_path(id: existing_screening[:id])

    stub_request(:post,
      ferb_api_url(FerbRoutes.screening_participant_path(existing_screening[:id])))
      .and_return(json_body('', status: 403))

    within '#search-card', text: 'Search' do
      accept_alert('You are not authorized to add this person.') do
        fill_in 'Search for any person', with: 'Marge'
        click_button 'Create a new person'
      end
    end
  end

  scenario 'adding a participant from search on show screening page' do
    visit screening_path(id: existing_screening[:id])
    stub_request(:get,
      ferb_api_url(
        FerbRoutes.client_authorization_path(
          homer[:legacy_descriptor][:legacy_id]
        )
      )).and_return(status: 200)

    stub_request(:post,
      ferb_api_url(FerbRoutes.screening_participant_path(existing_screening[:id])))
      .and_return(json_body(homer.to_json, status: 201))

    within '#search-card', text: 'Search' do
      fill_in 'Search for any person', with: 'Homer'
    end
    within '#search-card', text: 'Search' do
      find('strong', text: 'Homer Simpson').click
    end
    expect(a_request(:get,
      ferb_api_url(
        FerbRoutes.client_authorization_path(
          homer[:legacy_descriptor][:legacy_id]
        )
      )))
      .to have_been_made
    expect(a_request(:post,
      ferb_api_url(FerbRoutes.screening_participant_path(existing_screening[:id]))))
      .to have_been_made

    within edit_participant_card_selector(homer[:id]) do
      within '.card-header' do
        expect(page).to_not have_content('Sensitive')
        expect(page).to have_content 'Homer Simpson'
        expect(page).to have_button 'Remove person'
      end

      within '.card-body' do
        expect(page).to have_field('First Name', with: homer[:first_name])
        expect(page).to have_field('Last Name', with: homer[:last_name])
        expect(page).to have_field('Phone Number', with: '(971)287-6774')
        expect(page).to have_select('Phone Number Type', selected: homer[:phone_numbers].first[:type])
        expect(page).to have_field('Sex at Birth', with: homer[:gender])
        expect(page).to have_react_select_field(
          'Language(s) (Primary First)', with: homer[:languages]
        )
        expect(page).to have_field('Date of birth', with: homer_date_of_birth.strftime('%m/%d/%Y'))
        expect(page).to have_field('Social security number', with: homer[:ssn])

        # Address has legacy_id, and so should be read-only
        expect(page).not_to have_field('Address')
        expect(page).not_to have_field('City')
        expect(page).not_to have_field('State')
        expect(page).not_to have_field('Zip')
        within 'fieldset', text: 'Race' do
          expect(page).to have_checked_field('Asian')
          expect(page).to have_select(
            "participant-#{homer[:id]}-Asian-race-detail",
            selected: 'Chinese'
          )
          expect(page).to have_checked_field('White')
          expect(page).to have_select(
            "participant-#{homer[:id]}-White-race-detail",
            selected: 'Romanian'
          )
          expect(page).to have_checked_field('American Indian or Alaska Native')
        end
        within 'fieldset', text: 'Hispanic/Latino Origin' do
          expect(page).to have_checked_field('Yes')
          expect(page).to have_select(
            "participant-#{homer[:id]}-ethnicity-detail",
            selected: 'Hispanic'
          )
        end
        expect(page).to have_button 'Cancel'
        expect(page).to have_button 'Save'
      end
    end
  end

  context 'adding a sensitive participant from search results' do
    let(:sensitive_token) { 'SENSITIVE_TOKEN' }
    let(:insensitive_token) { 'INSENSITIVE_TOKEN' }

    before do
      stub_request(:get, %r{https?://.*/authn/validate\?token=#{sensitive_token}})
        .and_return(status: 200,
                    body: { staffId: '123', privileges: ['Sensitive Persons'] }.to_json)
      stub_request(:get, %r{https?://.*/authn/validate\?token=#{insensitive_token}})
        .and_return(status: 200, body: { staffId: '123', privileges: [] }.to_json)
      stub_request(:get, ferb_api_url(FerbRoutes.staff_path('123')))
        .and_return(json_body({ staffId: '123', first_name: 'Bob', last_name: 'Boberson',
                                county: 'San Francisco' }.to_json, status: 200))
      stub_county_agencies('c40')
    end

    context 'with NO privileges to add sensitive' do
      scenario 'cannot add sensitive' do
        if ENV.key?('TEST_ENV_NUMBER')
          skip 'Pending this test as it just fails on jenkins when the js alert is triggered'
        end
        Feature.run_with_activated(:authentication) do
          stub_empty_history_for_screening(existing_screening)
          stub_person_search(search_term: 'Marge', person_response: marge_response)
          stub_request(
            :post,
            ferb_api_url(FerbRoutes.screening_participant_path(existing_screening[:id]))
          ).and_return(json_body({}.to_json, status: 201))
          visit edit_screening_path(id: existing_screening[:id], token: insensitive_token)
          within '#search-card', text: 'Search' do
            accept_alert('You are not authorized to add this person.') do
              fill_in 'Search for any person', with: 'Marge'
              find('strong', text: 'Marge Simpson').click
            end
          end
        end
      end

      scenario 'can add insensitive' do
        Feature.run_with_activated(:authentication) do
          stub_empty_history_for_screening(existing_screening)
          visit edit_screening_path(id: existing_screening[:id], token: insensitive_token)
          stub_request(:get,
            ferb_api_url(
              FerbRoutes.client_authorization_path(
                homer[:legacy_descriptor][:legacy_id]
              )
            )).and_return(status: 200)
          stub_request(
            :post,
            ferb_api_url(
              FerbRoutes.screening_participant_path(existing_screening[:id])
            )
          ).and_return(json_body(homer.to_json, status: 201))
          within '#search-card', text: 'Search' do
            fill_in 'Search for any person', with: 'Ho'
            find('strong', text: 'Homer Simpson').click
          end
          # The new participant was NOT added
          expect(page)
            .to have_selector(edit_participant_card_selector(homer[:id]))
        end
      end
    end

    context 'with privileges to add sensitive' do
      scenario 'can add sensitive person' do
        Feature.run_with_activated(:authentication) do
          stub_empty_history_for_screening(existing_screening)
          visit edit_screening_path(id: existing_screening[:id], token: sensitive_token)
          sensitive_participant_marge = marge.merge(sensitive: true)
          created_participant_marge = marge

          stub_request(:get,
            ferb_api_url(
              FerbRoutes.client_authorization_path(
                sensitive_participant_marge[:legacy_descriptor][:legacy_id]
              )
            )).and_return(status: 200)
          stub_request(
            :post,
            ferb_api_url(
              FerbRoutes.screening_participant_path(existing_screening[:id])
            )
          ).and_return(json_body(created_participant_marge.to_json, status: 201))
          within '#search-card', text: 'Search' do
            fill_in 'Search for any person', with: 'Ma'
            find('strong', text: 'Marge Simpson').click
          end
          expect(
            a_request(
              :post,
              ferb_api_url(
                FerbRoutes.screening_participant_path(existing_screening[:id])
              )
            )
          ).to have_been_made
          created_participant_selector = edit_participant_card_selector(
            created_participant_marge[:id]
          )
          existing_participant_selector = edit_participant_card_selector(existing_participant[:id])
          expect(find("#{created_participant_selector}+div"))
            .to match_css(existing_participant_selector)

          expect(page)
            .to have_selector(edit_participant_card_selector(created_participant_marge[:id]))
          within edit_participant_card_selector(created_participant_marge[:id]) do
            within '.card-header' do
              expect(page).to have_content('Sensitive')
              expect(page).to have_content 'Marge Simpson'
              expect(page).to have_button 'Remove person'
            end
          end
        end
      end
      scenario 'can add sensitive person' do
        Feature.run_with_activated(:authentication) do
          stub_empty_history_for_screening(existing_screening)
          visit edit_screening_path(id: existing_screening[:id], token: sensitive_token)
          stub_request(:get,
            ferb_api_url(
              FerbRoutes.client_authorization_path(
                homer[:legacy_descriptor][:legacy_id]
              )
            )).and_return(status: 200)
          stub_request(
            :post,
            ferb_api_url(
              FerbRoutes.screening_participant_path(existing_screening[:id])
            )
          ).and_return(json_body(homer.to_json, status: 201))
          within '#search-card', text: 'Search' do
            fill_in 'Search for any person', with: 'Ho'
            find('strong', text: 'Homer Simpson').click
          end
          expect(page)
            .to have_selector(edit_participant_card_selector(homer[:id]))
        end
      end
    end
  end
end
