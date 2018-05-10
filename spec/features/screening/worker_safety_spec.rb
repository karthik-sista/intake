# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'factory_bot'

feature 'worker safety card' do
  let(:existing_screening) do
    {
      id: '1',
      incident_address: {},
      allegations: [],
      cross_reports: [],
      participants: [],
      safety_information: 'Important safety stuff',
      safety_alerts: ['Dangerous Environment']
    }
  end
  scenario 'user edits worker safety card from screening show page and cancels' do
    stub_and_visit_show_screening(existing_screening)
    click_link 'Edit worker safety'

    within '#worker-safety-card.edit' do
      expect(page).to have_field('Additional Safety Information', with: 'Important safety stuff')
      expect(page).to have_react_select_field(
        'Worker Safety Alerts', with: ['Dangerous Environment']
      )
      fill_in 'Additional Safety Information', with: 'Something else'
      fill_in_react_select 'Worker Safety Alerts', with: ['Firearms in Home']
      click_button 'Cancel'
    end

    within '#worker-safety-card.show' do
      expect(page).to have_content 'Important safety stuff'
      expect(page).to have_content 'Dangerous Environment'
      expect(page).not_to have_content 'Firearms in Home'
    end

    click_link 'Edit worker safety'

    within '#worker-safety-card.edit' do
      expect(page).to have_field('Additional Safety Information', with: 'Important safety stuff')
    end
  end

  scenario 'user edits worker safety card from screening edit page and cancels' do
    existing_screening.merge!(
      safety_information: 'Important safety stuff',
      safety_alerts: ['Dangerous Environment']
    )
    stub_and_visit_edit_screening(existing_screening)

    within '#worker-safety-card.edit' do
      expect(page).to have_field('Additional Safety Information', with: 'Important safety stuff')
      expect(page).to have_react_select_field(
        'Worker Safety Alerts', with: ['Dangerous Environment']
      )
      fill_in 'Additional Safety Information', with: 'Something else'
      fill_in_react_select 'Worker Safety Alerts', with: ['Firearms in Home']
      click_button 'Cancel'
    end

    within '#worker-safety-card.show' do
      expect(page).to have_content 'Important safety stuff'
      expect(page).to have_content 'Dangerous Environment'
      expect(page).not_to have_content 'Firearms in Home'
    end
  end

  scenario 'user edits worker safety card from screening show page and saves' do
    existing_screening.merge!(
      safety_information: 'Important safety stuff',
      safety_alerts: ['Dangerous Environment']
    )
    stub_and_visit_show_screening(existing_screening)
    click_link 'Edit worker safety'

    within '#worker-safety-card.edit' do
      expect(page).to have_field('Additional Safety Information', with: 'Important safety stuff')
      expect(page).to have_react_select_field(
        'Worker Safety Alerts', with: ['Dangerous Environment']
      )
      fill_in 'Additional Safety Information', with: 'Something else'
      fill_in_react_select 'Worker Safety Alerts', with: ['Firearms in Home']
    end

    existing_screening[:safety_information] = 'Something else'
    existing_screening[:safety_alerts] = ['Dangerous Environment', 'Firearms in Home']
    existing_screening[:address] = existing_screening.delete(:incident_address)
    stub_request(
      :put, intake_api_url(ExternalRoutes.intake_api_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json))

    within '#worker-safety-card.edit' do
      click_button 'Save'
    end

    expect(
      a_request(
        :put, intake_api_url(ExternalRoutes.intake_api_screening_path(existing_screening[:id]))
      )
    ).to have_been_made

    within '#worker-safety-card.show' do
      expect(page).to have_content 'Something else'
      expect(page).to have_content 'Dangerous Environment'
      expect(page).to have_content 'Firearms in Home'
    end
  end

  scenario 'user edits worker safety card from screening edit page and saves' do
    existing_screening.merge!(
      safety_information: 'Important safety stuff',
      safety_alerts: ['Dangerous Environment']
    )
    stub_and_visit_edit_screening(existing_screening)

    within '#worker-safety-card.edit' do
      expect(page).to have_field('Additional Safety Information', with: 'Important safety stuff')
      expect(page).to have_react_select_field(
        'Worker Safety Alerts', with: ['Dangerous Environment']
      )
      fill_in 'Additional Safety Information', with: 'Something else'
      fill_in_react_select 'Worker Safety Alerts', with: ['Firearms in Home']
      fill_in_react_select 'Worker Safety Alerts',
        with: ['Severe Mental Health Status'], exit_key: :tab
    end

    existing_screening[:safety_information] = 'Something else'
    existing_screening[:safety_alerts] = ['Dangerous Environment', 'Firearms in Home']
    existing_screening[:address] = existing_screening.delete(:incident_address)
    stub_request(
      :put, intake_api_url(ExternalRoutes.intake_api_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json))

    within '#worker-safety-card.edit' do
      click_button 'Save'
    end

    expect(
      a_request(
        :put, intake_api_url(ExternalRoutes.intake_api_screening_path(existing_screening[:id]))
      )
    ).to have_been_made

    within '#worker-safety-card.show' do
      expect(page).to have_content 'Something else'
      expect(page).to have_content 'Dangerous Environment'
      expect(page).to have_content 'Firearms in Home'
    end
  end
end
