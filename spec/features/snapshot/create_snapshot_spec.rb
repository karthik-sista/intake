# frozen_string_literal: true

require 'rails_helper'
require 'feature/testing'

feature 'Create Snapshot' do
  context 'when only snapshot is enabled' do
    around do |example|
      Feature.run_with_deactivated(:screenings) do
        example.run
      end
    end

    scenario 'via start snapshot link' do
      visit root_path
      click_button 'Start Snapshot'

      expect(page.current_url).to match 'snapshot'

      within '#snapshot-card' do
        expect(page).to have_content(
          'The Child Welfare History Snapshot allows you to search CWS/CMS for people and their'
        )
      end

      expect(page).to have_css('.side-bar')
      expect(page).to have_content('People & Roles')
      expect(page).to have_content('Relationships')
      expect(page).to have_content('History')
    end

    scenario 'user starts a snapshot, goes back to the home page, and starts another snapshot' do
      visit root_path
      click_button 'Start Snapshot'

      person = FactoryBot.create(:participant, first_name: 'Marge')
      search_response = PersonSearchResponseBuilder.build do |response|
        response.with_total(1)
        response.with_hits do
          [
            PersonSearchResultBuilder.build do |builder|
              builder.with_first_name('Marge')
              builder.with_legacy_descriptor(person.legacy_descriptor)
            end
          ]
        end
      end
      stub_person_search(search_term: 'Ma', person_response: search_response)
      stub_request(
        :get,
        ferb_api_url(FerbRoutes.client_authorization_path(person.legacy_descriptor.legacy_id))
      ).and_return(json_body('', status: 200))
      stub_person_find(id: person.legacy_descriptor.legacy_id, person_response: search_response)
      stub_request(
        :get,
        ferb_api_url(
          FerbRoutes.relationships_path
        ) + "?clientIds=#{person.legacy_descriptor.legacy_id}"
      ).and_return(json_body([].to_json, status: 200))
      stub_empty_history_for_clients [person.legacy_descriptor.legacy_id]

      within '#search-card', text: 'Search' do
        fill_in 'Search for clients', with: 'Ma'
        page.find('strong', text: 'Marge').click
      end

      within show_participant_card_selector(person.legacy_descriptor.legacy_id) do
        within '.card-body' do
          expect(page).to have_content(person.first_name)
        end
      end

      page.driver.go_back

      click_button 'Start Snapshot'

      expect(page).not_to have_css(
        show_participant_card_selector(person.legacy_descriptor.legacy_id)
      )
    end

    scenario 'a new snapshot is created if the user visits the snapshot page directly' do
      visit snapshot_path
      expect(page).to have_content('The Child Welfare History Snapshot allows you to search')
    end
  end

  context 'when snapshot is not enabled' do
    around do |example|
      Feature.run_with_deactivated(:snapshot) do
        example.run
      end
    end

    scenario 'snapshot page is not accessible' do
      visit snapshot_path
      expect(page).to have_content('Sorry, this is not the page you want')
    end
  end

  context 'both snapshot and screening are enabled' do
    let(:new_screening) do
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

    before do
      allow(LUID).to receive(:generate).and_return(['DQJIYK'])
    end

    scenario 'user starts a screening, goes back to the home page, and starts a snapshot' do
      stub_request(:get, ferb_api_url(FerbRoutes.screenings_path)).and_return(
        json_body([], status: 200)
      )
      visit root_path

      stub_empty_history_for_screening(new_screening)
      stub_empty_relationships
      stub_request(:post, ferb_api_url(FerbRoutes.intake_screenings_path))
        .and_return(json_body(new_screening.to_json, status: 201))
      stub_request(
        :get, ferb_api_url(FerbRoutes.intake_screening_path(new_screening[:id]))
      ).and_return(json_body(new_screening.to_json, status: 200))
      click_button 'Start Screening'

      search_response = PersonSearchResponseBuilder.build do |response|
        response.with_total(1)
        response.with_hits do
          [
            PersonSearchResultBuilder.build do |builder|
              builder.with_first_name('Marge')
            end
          ]
        end
      end
      stub_person_search(search_term: 'Ma', person_response: search_response)
      person = FactoryBot.create(
        :participant,
        first_name: 'Marge',
        screening_id: new_screening[:id]
      )
      stub_request(
        :post,
        intake_api_url(ExternalRoutes.intake_api_screening_people_path(new_screening[:id]))
      ).and_return(json_body(person.to_json, status: 201))

      within '#search-card', text: 'Search' do
        fill_in 'Search for any person', with: 'Ma'
        page.find('strong', text: 'Marge').click
      end

      within edit_participant_card_selector(person.id) do
        within '.card-header' do
          expect(page).to have_content(person.first_name)
        end
      end

      page.driver.go_back

      click_button 'Start Snapshot'

      within '#snapshot-card' do
        expect(page).to have_content(
          'The Child Welfare History Snapshot allows you to search CWS/CMS for people and their'
        )
      end
      expect(page).not_to have_css(
        show_participant_card_selector(person.legacy_descriptor.legacy_id)
      )
    end
  end
end
