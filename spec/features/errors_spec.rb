# frozen_string_literal: true

require 'rails_helper'
require 'feature/testing'

feature 'error pages' do
  let(:base_path) { 'intake' }
  around do |example|
    Rails.application.config.consider_all_requests_local = false
    Rails.application.config.action_dispatch.show_exceptions = true
    example.run
    Rails.application.config.consider_all_requests_local = true
    Rails.application.config.action_dispatch.show_exceptions = false
  end
  let(:screening) { FactoryBot.create(:screening, :submittable) }

  context 'page does not exist' do
    scenario 'renders 404 page' do
      if ENV.key?('TEST_ENV_NUMBER')
        skip 'Pending as this test fails during parallel runs'
      end
      stub_request(:get, '/this_page_does_not_exist').and_return(json_body('NotFound', status: 404))
      visit '/this_page_does_not_exist'
      expect(page).to have_text('Sorry, this is not the page you want.')
      expect(page).to have_text(
        "It may have been deleted or doesn't exist. Please check the address or"
      )
      expect(page).to have_link('return to your dashboard', href: '/')
    end
  end

  context 'screening does not exist' do
    before(:each) do
      stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening.id)))
        .and_return(json_body('Screening is not found!!', status: 404))
      stub_empty_relationships
      stub_empty_history_for_screening(screening)
      visit edit_screening_path(id: screening.id)
    end

    scenario 'renders not found error page' do
      expect(page).to have_text('Sorry, this is not the page you want.')
      expect(page).to have_text(
        "It may have been deleted or doesn't exist. Please check the address or"
      )
      expect(page).to have_link('return to your dashboard', href: '/')
    end

    scenario 'does not display "Something went wrong, sorry! Please try your last action again."' do
      stub_request(:get, ferb_api_url(FerbRoutes.screenings_path)).and_return(
        json_body([], status: 200)
      )
      click_link 'return to your dashboard'
      expect(page).not_to \
        have_text('Something went wrong, sorry! Please try your last action again.')
    end
  end

  context 'when user attempts to access a screening created by another' do
    scenario 'renders 403 page' do
      stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening.id)))
        .and_return(json_body('Forbidden!!', status: 403))
      stub_empty_relationships
      stub_empty_history_for_screening(screening)
      visit edit_screening_path(id: screening.id)
      expect(page).to have_current_path('/forbidden')
      expect(page).to have_text('This page is restricted.')
      expect(page).to have_text("You don't have the appropriate permissions to view this page.")
      expect(page).to have_link('Return to your dashboard', href: '/')
    end
  end

  context 'server has error' do
    scenario 'renders error banner' do
      expect(ScreeningRepository).to receive(:search).and_raise(StandardError)
      visit root_path

      expect(page).to have_text(
        /Something went wrong, sorry! Please try your last action again. \(Ref #:.*\)/
      )
    end
  end
end

feature 'error banner' do
  let(:screening) do
    { id: '1' }
  end
  context 'error occurred after page was loaded' do
    let(:referral_id) { FFaker::Guid.guid }
    let(:screening) do
      {
        id: '1',
        started_at: Time.now,
        assignee: 'Jane Smith',
        report_narrative: 'My narrative',
        screening_decision: 'differential_response',
        communication_method: 'fax',
        incident_address: {},
        addresses: [],
        cross_reports: [],
        participants: [],
        allegations: [],
        safety_alerts: ['Firearms in Home'],
        safety_information: ['Scary and dangerous']
      }
    end

    let(:api_response) { screening[:address] = screening.delete(:incident_address) }

    scenario 'hide the error banner after submit action succeeds on second try' do
      stub_request(
        :get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id]))
      ).and_return(json_body(screening.to_json, status: 200))
      stub_empty_relationships
      stub_empty_history_for_screening(screening)
      visit edit_screening_path(id: screening[:id])
      stub_request(
        :post,
        intake_api_url(ExternalRoutes.intake_api_screening_submit_path(screening[:id]))
      ).and_return(json_body([].to_json, status: 500))
      visit edit_screening_path(id: screening[:id])
      expect(page).to_not have_text(
        'Something went wrong, sorry! Please try your last action again.'
      )
      cancel_all_cards
      click_button 'Submit'
      expect(page).to have_text(
        'Something went wrong, sorry! Please try your last action again.'
      )
      screening[:referral_id] = referral_id
      stub_request(
        :post,
        intake_api_url(ExternalRoutes.intake_api_screening_submit_path(screening[:id]))
      ).and_return(json_body(api_response.to_json, status: 201))
      click_button 'Submit'

      expect(page).to_not have_text(
        'Something went wrong, sorry! Please try your last action again.'
      )
    end
  end
end
