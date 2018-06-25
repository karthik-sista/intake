# frozen_string_literal: true

require 'rails_helper'
require 'feature/testing'

feature 'Delete Participant' do
  let(:participant) do
    {
      id: '1',
      screening_id: '1',
      phone_numbers: [],
      languages: [],
      addresses: [],
      roles: []
    }
  end
  let(:screening) do
    {
      id: '1',
      cross_reports: [],
      allegations: [],
      incident_address: {},
      safety_alerts: [],
      participants: [participant]
    }
  end

  before do
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_request(
      :delete,
      ferb_api_url(FerbRoutes.delete_screening_participant_path(screening[:id], participant[:id]))
    ).and_return(json_body(nil, status: 204))
    stub_empty_relationships
    stub_empty_history_for_screening(screening)
  end

  scenario 'removing a participant from an existing screening in edit mode' do
    visit edit_screening_path(id: screening[:id])

    within edit_participant_card_selector(participant[:id]) do
      expect(page).to have_content(participant[:first_name])
    end

    screening[:participants] = []
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within edit_participant_card_selector(participant[:id]) do
      within '.card-header' do
        click_button 'Remove person'
      end
    end
    expect(
      a_request(:delete,
        ferb_api_url(FerbRoutes.delete_screening_participant_path(screening[:id], participant[:id])))
    ).to have_been_made
    expect(page).to_not have_css(edit_participant_card_selector(participant[:id]))
  end

  scenario 'removing a participant from an existing screening in show mode' do
    visit screening_path(id: screening[:id])

    screening[:participants] = []
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within show_participant_card_selector(participant[:id]) do
      within '.card-header' do
        click_button 'Remove person'
      end
    end
    expect(
      a_request(:delete,
        ferb_api_url(FerbRoutes.delete_screening_participant_path(screening[:id], participant[:id])))
    ).to have_been_made
    expect(page).to_not have_css(show_participant_card_selector(participant[:id]))
  end
end
