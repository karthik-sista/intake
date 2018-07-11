# frozen_string_literal: true

require 'rails_helper'

feature 'screening narrative card' do
  let(:existing_screening) do
    {
      id: '1',
      report_narrative: 'This is my report narrative',
      incident_address: {},
      addresses: [],
      cross_reports: [],
      participants: [],
      allegations: [],
      safety_alerts: []
    }
  end
  scenario 'user edits narrative card from screening show page and cancels' do
    stub_request(
      :get, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)

    visit screening_path(id: existing_screening[:id])
    click_link 'Edit narrative'

    within '#narrative-card.edit' do
      expect(page).to have_field('Report Narrative', with: 'This is my report narrative')
      fill_in 'Report Narrative', with: 'Trying to fill in'
      click_button 'Cancel'
    end

    within '#narrative-card.show' do
      expect(page).to have_content 'This is my report narrative'
    end
    visit current_url + '#search-card'
    click_link 'Edit narrative'

    within '#narrative-card.edit' do
      expect(page).to have_field('Report Narrative', with: 'This is my report narrative')
    end
  end

  scenario 'user edits narrative card from screening edit page and cancels' do
    stub_request(
      :get, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)

    visit edit_screening_path(id: existing_screening[:id])

    within '#narrative-card.edit' do
      expect(page).to have_field('Report Narrative', with: 'This is my report narrative')
      fill_in 'Report Narrative', with: 'Trying to fill in'
      click_button 'Cancel'
    end

    within '#narrative-card.show' do
      expect(page).to have_content 'This is my report narrative'
    end
  end

  scenario 'user edits narrative card from screening show page and saves' do
    stub_request(
      :get, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)

    visit screening_path(id: existing_screening[:id])
    click_link 'Edit narrative'

    within '#narrative-card.edit' do
      expect(page).to have_field('Report Narrative', with: 'This is my report narrative')
      fill_in 'Report Narrative', with: 'Trying to fill in with changes'
    end

    existing_screening[:report_narrative] = 'Trying to fill in with changes'
    stub_request(
      :put, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)

    within '#narrative-card.edit' do
      click_button 'Save'
    end

    expect(
      a_request(:put, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id])))
        .with(body: hash_including(existing_screening))
    ).to have_been_made
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)

    within '#narrative-card.show' do
      expect(page).to have_content 'Trying to fill in with changes'
    end
  end

  scenario 'user edits narrative card from screening edit page and saves' do
    stub_request(
      :get, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)

    visit edit_screening_path(id: existing_screening[:id])

    within '#narrative-card.edit' do
      expect(page).to have_field('Report Narrative', with: 'This is my report narrative')
      fill_in 'Report Narrative', with: 'Trying to fill in with changes'
    end

    existing_screening[:report_narrative] = 'Trying to fill in with changes'
    stub_request(
      :put, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)

    within '#narrative-card.edit' do
      click_button 'Save'
    end

    expect(
      a_request(:put, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id])))
        .with(body: hash_including(existing_screening))
    ).to have_been_made

    within '#narrative-card.show' do
      expect(page).to have_content 'Trying to fill in with changes'
    end
  end
end
