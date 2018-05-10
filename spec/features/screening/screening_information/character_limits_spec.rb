# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'factory_bot'

feature 'screening information card' do
  let(:screening) do
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
  let(:character_buffet) { 'C am-r\'o’n1234567890!@#$%^&*(),./;"[]' }

  scenario 'character limitations by field' do
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_relationships
    stub_empty_history_for_screening(screening)
    visit edit_screening_path(id: screening[:id])

    within '#screening-information-card.edit' do
      fill_in 'Title/Name of Screening', with: character_buffet
      fill_in 'Assigned Social Worker', with: character_buffet
      expect(page).to have_field('Title/Name of Screening', with: "C am-r'o’n")
      expect(page).to have_field('Assigned Social Worker', with: 'C amron')
    end
  end
end
