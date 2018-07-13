# frozen_string_literal: true

require 'rails_helper'
require 'feature/testing'

feature 'CSEC validation' do
  let(:victim) { FactoryBot.create(:participant, :victim) }
  let(:screening) do
    {
      id: '1',
      name: 'James',
      assignee: 'Lisa',
      report_type: 'csec',
      started_at: '2016-08-13T10:00:00.000Z',
      ended_at: '2016-08-15T11:00:00.000Z',
      communication_method: 'mail',
      incident_address: {},
      addresses: [],
      cross_reports: [],
      participants: [victim.as_json.symbolize_keys],
      allegations: [],
      safety_alerts: []
    }
  end

  before do
    stub_system_codes
    stub_and_visit_edit_screening(screening)
  end
  context 'csec start date field' do
    let(:csec_start_date_error_message) { 'Start date must be entered.' }
    scenario 'displays an error if the user does not enter a start date' do
      stub_and_visit_edit_screening(screening)
      within "#participants-card-#{victim.id}" do
        expect(page).to have_content('CSEC Start Date')
        expect(page).not_to have_content(csec_start_date_error_message)
        click_button 'Cancel'
        expect(page).to have_content(csec_start_date_error_message)
        visit current_url + '#search-card'
        click_link 'Edit'
        fill_in_datepicker 'CSEC Start Date', with: '', blur: false
        expect(page).not_to have_content(csec_start_date_error_message)
        blur_field
        page.execute_script 'window.scrollBy(0,100)'
        expect(page).to have_content(csec_start_date_error_message)
        fill_in_datepicker 'CSEC Start Date', with: '06-11-2018', blur: true
        expect(page).not_to have_content(csec_start_date_error_message)

        updated_participant = victim.as_json.merge(
          csec: [{
            id: '1',
            participant_id: victim.id,
            start_date: '06-11-2018'
          }]
        )

        stub_request(:put,
          ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], victim.id)))
          .and_return(json_body(updated_participant.to_json, status: 200))
        click_button 'Save'
        expect(page).to have_content('CSEC Start Date')
        expect(page).not_to have_content(csec_start_date_error_message)
        click_link 'Edit'
        fill_in_datepicker 'CSEC Start Date', with: '', blur: false
        blur_field
        expect(page).to have_content(csec_start_date_error_message)
      end
    end
  end
  context 'csec types field' do
    let(:csec_types_error_message) { 'CSEC type must be selected.' }
    scenario 'displays an error if the user does not enter a csec types' do
      within "#participants-card-#{victim.id}" do
        expect(page).to have_content('CSEC Types')
        expect(page).not_to have_content(csec_types_error_message)
        click_button 'Cancel'
        expect(page).to have_content(csec_types_error_message)
        visit current_url + '#search-card'
        click_link 'Edit'
        page.execute_script 'window.scrollBy(0,100)'
        expect(page).not_to have_content(csec_types_error_message)
        fill_in_react_select 'CSEC Types', with: ''
        blur_field
        expect(page).to have_content(csec_types_error_message)
        fill_in_react_select 'CSEC Types', with: 'At Risk'
        blur_field
        expect(page).not_to have_content(csec_types_error_message)

        updated_participant = victim.as_json.merge(
          csec: [{
            id: '2',
            participant_id: victim.id,
            csec_code_id: '8688'
          }]
        )

        stub_request(:put,
          ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], victim.id)))
          .and_return(json_body(updated_participant.to_json, status: 200))

        click_button 'Save'
        expect(page).to have_content('CSEC Types')
        expect(page).not_to have_content(csec_types_error_message)
      end
    end
  end
  context 'csec fields' do
    scenario 'show csec type, csec start date and csec end date' do
      stub_and_visit_edit_screening(screening)
      within "#participants-card-#{victim.id}" do
        expect(page).to have_content('CSEC Start Date')
        expect(page).to have_content('CSEC End Date')
        expect(page).to have_content('CSEC Types')

        updated_participant = victim.as_json.merge(
          csec: [{
            id: '1',
            participant_id: victim.id,
            end_date: '2018-11-13',
            start_date: '2018-11-12',
            csec_code_id: '8688'
          }]
        )

        stub_request(:put,
          ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], victim.id)))
          .and_return(json_body(updated_participant.to_json, status: 200))

        click_button 'Save'
        expect(page).to have_content('CSEC End Date')
        expect(page).to have_content('11/13/2018')
        expect(page).to have_content('CSEC Start Date')
        expect(page).to have_content('11/12/2018')
        expect(page).to have_content('CSEC Types')
        expect(page).to have_content('At Risk')
      end
    end
  end
end
