# frozen_string_literal: true

require 'rails_helper'

feature 'System codes' do
  scenario 'system codes are fetch once per page load' do
    stub_request(:get, ferb_api_url(FerbRoutes.screenings_path))
      .and_return(json_body([].to_json, status: 200))
    stub_request(:post, ferb_api_url(FerbRoutes.create_screening_path))
      .and_return(json_body([].to_json, status: 200))
    stub_request(:get, ferb_api_url(FerbRoutes.lov_path))
      .and_return(json_body([].to_json, status: 200))
    visit root_path
    click_button 'Start Screening'
    expect(a_request(:get, ferb_api_url(FerbRoutes.lov_path))).to have_been_made.once
  end
end
