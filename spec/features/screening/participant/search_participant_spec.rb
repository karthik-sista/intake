# frozen_string_literal: true

require 'rails_helper'
require 'feature/testing'

feature 'searching a participant in autocompleter' do
  let(:existing_screening) do
    {
      id: '1',
      incident_address: {},
      addresses: [],
      cross_reports: [],
      participants: [],
      allegations: [],
      safety_alerts: []
    }
  end
  let(:date_of_birth) { 15.years.ago.to_date }
  before do
    stub_request(
      :get, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)
    stub_system_codes
  end

  context 'search for a person' do
    before do
      visit edit_screening_path(id: existing_screening[:id])
    end

    scenario 'search result contains person information' do
      search_response = PersonSearchResponseBuilder.build do |response|
        response.with_total(1)
        response.with_hits do
          [
            PersonSearchResultBuilder.build do |builder|
              builder.with_first_name('Marge')
              builder.with_middle_name('Jacqueline')
              builder.with_last_name('Simpson')
              builder.with_name_suffix('md')
              builder.with_gender('female')
              builder.with_date_of_birth(date_of_birth)
              builder.with_ssn('123231234')
              builder.with_languages do
                [
                  LanguageSearchResultBuilder.build('French') do |language|
                    language.with_primary true
                  end,
                  LanguageSearchResultBuilder.build('Italian')
                ]
              end
              builder.with_phone_number(number: '9712876774', type: 'Home')
              builder.with_addresses do
                [
                  AddressSearchResultBuilder.build do |address|
                    address.with_street_number('123')
                    address.with_street_name('Fake St')
                    address.with_state_code('NY')
                    address.with_city('Springfield')
                    address.with_zip('11222')
                    address.with_phone_number(number: '6035550123', type: 'Home')
                    address.with_type do
                      AddressTypeSearchResultBuilder.build('Home')
                    end
                  end
                ]
              end
              builder.with_race_and_ethnicity do
                RaceEthnicitySearchResultBuilder.build do |race_ethnicity|
                  race_ethnicity.with_hispanic_origin_code('Y')
                  race_ethnicity.with_hispanic_unable_to_determine_code('')
                  race_ethnicity.with_race_codes do
                    [
                      RaceCodesSearchResultBuilder.build('White'),
                      RaceCodesSearchResultBuilder.build('American Indian or Alaska Native')
                    ]
                  end
                end
              end
              builder.with_sensitivity
              builder.with_sort('1')
            end
          ]
        end
      end
      stub_person_search(search_term: 'Ma', person_response: search_response)

      within '#search-card', text: 'Search' do
        fill_in 'Search for any person', with: 'Ma'
      end

      within_person_search_result(name: 'Marge Jacqueline Simpson, MD') do
        expect(page).to have_content date_of_birth.strftime('%-m/%-d/%Y')
        expect(page).to have_content '15 yrs old'
        expect(page).to have_content 'Female, White, American Indian or Alaska Native'
        expect(page).to have_content 'Hispanic/Latino'
        expect(page).to have_content 'Language'
        expect(page).to have_content 'French (Primary), Italian'
        expect(page).to have_content 'Home(603) 555-0123'
        expect(page).to have_content 'SSN'
        expect(page).to have_content '1234'
        expect(page).to have_content '123-23-1234'
        expect(page).to have_content 'Home123 Fake St, Springfield, NY 11222'
        expect(page).to have_content 'Sensitive'
        expect(page).to_not have_content 'Sealed'
      end
    end

    scenario 'search results format the SSN' do
      search_response = PersonSearchResponseBuilder.build do |response|
        response.with_total(1)
        response.with_hits do
          [
            PersonSearchResultBuilder.build do |builder|
              builder.with_first_name('Marge')
              builder.with_ssn('123456789')
            end
          ]
        end
      end
      stub_person_search(search_term: 'Ma 12345', person_response: search_response)
      within '#search-card', text: 'Search' do
        fill_in 'Search for any person', with: 'Ma 123-45'
      end

      within '#search-card', text: 'Search' do
        expect(page).to have_content '123-45-6789'
      end

      expect(
        a_request(
          :post,
          dora_api_url(ExternalRoutes.dora_people_light_index_path)
        ).with('body' => {
                 'query' => {
                   'bool' => {
                     'must' => anything,
                     'should' => anything
                   }
                 },
                 '_source' => anything,
                 'highlight' => anything,
                 'track_scores' => anything,
                 'sort' => anything,
                 'size' => anything
               })
      ).to have_been_made
    end

    context 'closes search results' do
      before do
        legacy_descriptor = FactoryBot.create(:legacy_descriptor)
        search_response = PersonSearchResponseBuilder.build do |response|
          response.with_total(1)
          response.with_hits do
            [
              PersonSearchResultBuilder.build do |builder|
                builder.with_first_name('Marge')
                builder.with_legacy_descriptor(legacy_descriptor)
              end
            ]
          end
        end
        stub_person_search(search_term: 'Ma', person_response: search_response)
        stub_request(
          :get,
          ferb_api_url(FerbRoutes.client_authorization_path(legacy_descriptor.legacy_id))
        ).and_return(status: 200)
        stub_request(
          :post,
          ferb_api_url(FerbRoutes.screening_participant_path(existing_screening[:id]))
        ).and_return(json_body({
          id: '1',
          screening_id: existing_screening[:id],
          legacy_descriptor: {
            legacy_id: legacy_descriptor.legacy_id,
            legacy_source_table: legacy_descriptor.legacy_table_name
          },
          addresses: [],
          roles: []
        }.to_json, status: 201))

        within '#search-card', text: 'Search' do
          fill_in 'Search for any person', with: 'Ma'
        end
      end

      scenario 'when clicking search result' do
        within '#search-card', text: 'Search' do
          page.find('strong', text: 'Marge').click
        end

        within '#search-card', text: 'Search' do
          expect(page).to_not have_button('Create a new person')
        end
      end

      scenario 'when clicking outside search result' do
        page.find('#screening-information-card').click

        within '#search-card', text: 'Search' do
          expect(page).to_not have_button('Create a new person')
        end
      end
    end

    scenario 'results include information about the legacy source information for a person' do
      search_response = PersonSearchResponseBuilder.build do |response|
        response.with_total(1)
        response.with_hits do
          [
            PersonSearchResultBuilder.build do |builder|
              builder.with_first_name('Marge')
              builder.with_legacy_descriptor(
                legacy_ui_id: '123-456-789',
                legacy_table_description: 'Client'
              )
            end
          ]
        end
      end
      stub_person_search(search_term: 'Ma', person_response: search_response)
      within '#search-card', text: 'Search' do
        fill_in 'Search for any person', with: 'Ma'
      end
      within '#search-card', text: 'Search' do
        expect(page).to have_content 'Client ID 123-456-789 in CWS-CMS'
      end
    end

    scenario 'person without last known phone_numbers' do
      search_response = PersonSearchResponseBuilder.build do |response|
        response.with_total(1)
        response.with_hits do
          [
            PersonSearchResultBuilder.build do |builder|
              builder.with_first_name('Marge')
              builder.with_middle_name('Jacqueline')
              builder.with_last_name('Simpson')
              builder.with_name_suffix('md')
              # Phone numbers should be pulled from addresses, not here.
              builder.with_phone_number(number: '6035550123', type: 'Home')
            end
          ]
        end
      end
      stub_person_search(search_term: 'Ma', person_response: search_response)
      within '#search-card', text: 'Search' do
        fill_in 'Search for any person', with: 'Ma'
      end
      within_person_search_result(name: 'Marge Jacqueline Simpson, MD') do
        expect(page).to_not have_css 'fa-phone'
      end
    end

    scenario 'person without addresses' do
      search_response = PersonSearchResponseBuilder.build do |response|
        response.with_total(1)
        response.with_hits do
          [
            PersonSearchResultBuilder.build do |builder|
              builder.with_first_name('Marge')
              builder.with_middle_name('Jacqueline')
              builder.with_last_name('Simpson')
              builder.with_name_suffix('md')
              builder.with_addresses { [] }
            end
          ]
        end
      end
      stub_person_search(search_term: 'Ma', person_response: search_response)
      within '#search-card', text: 'Search' do
        fill_in 'Search for any person', with: 'Ma'
      end
      within_person_search_result(name: 'Marge Jacqueline Simpson, MD') do
        expect(page).to_not have_css 'fa-map-marker'
      end
    end

    scenario 'person who is neither sensitive nor sealed' do
      search_response = PersonSearchResponseBuilder.build do |response|
        response.with_total(1)
        response.with_hits do
          [
            PersonSearchResultBuilder.build do |builder|
              builder.with_first_name('Marge')
              builder.without_sealed_or_sensitive
            end
          ]
        end
      end
      stub_person_search(search_term: 'Ma', person_response: search_response)
      within '#search-card', text: 'Search' do
        fill_in 'Search for any person', with: 'Ma'
      end
      within_person_search_result(name: 'Marge') do
        expect(page).to_not have_content 'Sensitive'
        expect(page).to_not have_content 'Sealed'
      end
    end

    scenario 'person who is sensitive' do
      search_response = PersonSearchResponseBuilder.build do |response|
        response.with_total(1)
        response.with_hits do
          [
            PersonSearchResultBuilder.build do |builder|
              builder.with_first_name('Marge')
              builder.with_sensitivity
            end
          ]
        end
      end
      stub_person_search(search_term: 'Ma', person_response: search_response)
      within '#search-card', text: 'Search' do
        fill_in 'Search for any person', with: 'Ma'
      end
      within_person_search_result(name: 'Marge') do
        expect(page).to have_content 'Sensitive'
        expect(page).to_not have_content 'Sealed'
      end
    end

    scenario 'person who is sealed' do
      search_response = PersonSearchResponseBuilder.build do |response|
        response.with_total(1)
        response.with_hits do
          [
            PersonSearchResultBuilder.build do |builder|
              builder.with_first_name('Marge')
              builder.with_sealed
            end
          ]
        end
      end
      stub_person_search(search_term: 'Ma', person_response: search_response)
      within '#search-card', text: 'Search' do
        fill_in 'Search for any person', with: 'Ma'
      end

      within_person_search_result(name: 'Marge') do
        expect(page).to_not have_content 'Sensitive'
        expect(page).to have_content 'Sealed'
      end
    end

    scenario 'search displays no results when none are returned' do
      no_search_results = PersonSearchResponseBuilder.build do |builder|
        builder.with_total(0)
        builder.with_hits { [] }
      end
      stub_person_search(search_term: 'No', person_response: no_search_results)
      within '#search-card', text: 'Search' do
        fill_in 'Search for any person', with: 'No'
        expect(page).to have_content 'No results were found for "No"'
      end
    end

    scenario 'person search supports pagination' do
      search_results_one = PersonSearchResponseBuilder.build do |builder|
        builder.with_total(51)
        builder.with_hits do
          Array.new(25) do |index|
            PersonSearchResultBuilder.build do |result|
              result.with_first_name("Result #{index}")
              result.with_sort(["result_#{index}_score", "result_#{index}_uuid"])
            end
          end
        end
      end
      search_results_two = PersonSearchResponseBuilder.build do |builder|
        builder.with_total(51)
        builder.with_hits do
          Array.new(25) do |index|
            PersonSearchResultBuilder.build do |result|
              result.with_first_name("Result #{index + 25}")
              result.with_sort(["result_#{index + 25}_score", "result_#{index + 25}_uuid"])
            end
          end
        end
      end
      search_results_three = PersonSearchResponseBuilder.build do |builder|
        builder.with_total(51)
        builder.with_hits do
          [
            PersonSearchResultBuilder.build do |result|
              result.with_first_name('Result 50')
              result.with_sort(%w[result_50_score result_50_uuid])
            end
          ]
        end
      end
      stub_person_search(search_term: 'Fi', person_response: search_results_one)
      stub_person_search(
        search_term: 'Fi',
        person_response: search_results_two,
        search_after: %w[result_24_score result_24_uuid]
      )
      stub_person_search(
        search_term: 'Fi',
        person_response: search_results_three,
        search_after: %w[result_49_score result_49_uuid]
      )
      search_path = dora_api_url(ExternalRoutes.dora_people_light_index_path)
      within '#search-card', text: 'Search' do
        fill_in 'Search for any person', with: 'Fi'
        expect(page).to have_content 'Showing 1-25 of 51 results for "Fi"', wait: 3
        expect(page).to have_content 'Result 24'
      end
      expect(a_request(:post, search_path)).to have_been_made

      within '#search-card', text: 'Search' do
        click_button 'Show more results'
      end
      within '#search-card', text: 'Search' do
        expect(page).to have_content 'Showing 1-50 of 51 results for "Fi"'
        expect(page).to have_content 'Result 49'
      end
      expect(
        a_request(:post, search_path)
        .with(body: hash_including('search_after' => %w[result_24_score result_24_uuid]))
      ).to have_been_made

      # Show more results button doesnot load results when it is clicked
      # second time. This is a known bug.
      click_link('People & Roles')
      page.find('input[id="screening_participants"]').click

      within '#search-card', text: 'Search' do
        click_button 'Show more results'
      end
      within '#search-card', text: 'Search' do
        expect(page).to have_content 'Showing 1-51 of 51 results for "Fi"'
        expect(page).to have_content 'Result 50'
      end
      expect(
        a_request(:post, search_path)
        .with(body: hash_including('search_after' => %w[result_49_score result_49_uuid]))
      ).to have_been_made

      within '#search-card', text: 'Search' do
        expect(page).to_not have_button('Show more results')
      end
    end
  end

  it_behaves_like :authenticated do
    scenario 'clear search input on navigation' do
      allow(LUID).to receive(:generate).and_return(['DQJIYK'])
      new_screening = {
        id: '1',
        reference: 'DQJIYK',
        assignee: 'Joe Cool',
        assignee_staff_id: nil,
        incident_county: nil,
        indexable: true,
        incident_address: {},
        addresses: [],
        cross_reports: [],
        participants: [],
        allegations: [],
        safety_alerts: []
      }
      stub_empty_history_for_screening(new_screening)
      stub_empty_relationships
      stub_request(:post, ferb_api_url(FerbRoutes.intake_screenings_path))
        .with(body: new_screening.as_json(except: %i[id safety_alerts]))
        .and_return(json_body(new_screening.to_json, status: 201))

      stub_request(:get, ferb_api_url(FerbRoutes.screenings_path))
        .and_return(json_body([].to_json, status: 200))

      stub_request(:get,
        ferb_api_url(FerbRoutes.intake_screening_path(new_screening[:id])))
        .and_return(json_body(new_screening.to_json, status: 200))

      visit root_path(accessCode: access_code)
      click_button 'Start Screening'

      stub_person_search(search_term: 'Go back', person_response: { hits: { total: 1, hits: [] } })
      within '#search-card', text: 'Search' do
        fill_in 'Search for any person', with: 'Go back'
      end

      stub_request(:get, ferb_api_url(FerbRoutes.screenings_path))
        .and_return(json_body([].to_json, status: 200))

      page.go_back

      stub_empty_history_for_screening(new_screening)
      stub_empty_relationships
      stub_request(:get,
        ferb_api_url(FerbRoutes.intake_screening_path(new_screening[:id])))
        .and_return(json_body(new_screening.to_json, status: 200))

      page.go_forward

      expect(find_field('Search for any person').value).to eq ''
    end
  end
end
