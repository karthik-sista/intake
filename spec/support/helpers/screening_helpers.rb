# frozen_string_literal: true

module ScreeningHelpers
  def edit_participant_card_selector(participant_id)
    "#participants-card-#{participant_id}.edit"
  end

  def show_participant_card_selector(participant_id)
    "#participants-card-#{participant_id}.show"
  end

  def save_card(card_name)
    within "##{card_name}-card.edit" do
      click_button 'Save'
    end
  end

  def edit_card(card_name)
    within "##{card_name}-card.show" do
      click_link 'Edit'
    end
  end

  def stub_empty_relationships
    stub_request(
      :get,
      ferb_api_url(FerbRoutes.relationships_path)
    ).with(query: hash_including({})).and_return(json_body([].to_json, status: 200))
  end

  def stub_empty_history_for_screening(screening, response: { cases: [],
                                                              referrals: [],
                                                              screenings: [] })
    screening_id = if screening.is_a?(Hash)
                     screening[:id]
                   else
                     screening.id
                   end
    stub_request(
      :get,
      ferb_api_url(FerbRoutes.screening_history_of_involvements_path(screening_id))
    ).and_return(json_body(response.to_json, status: 200))
  end

  def stub_empty_history_for_clients(ids)
    params = ids.map { |id| "clientIds=#{id}" }.join '&'
    stub_request(
      :get,
      ferb_api_url(
        FerbRoutes.history_of_involvements_path
      ) + "?#{params}"
    ).and_return(json_body({ cases: [], referrals: [], screenings: [] }.to_json, status: 200))
  end

  def stub_and_visit_edit_screening(screening)
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_relationships
    stub_empty_history_for_screening(screening)

    visit edit_screening_path(id: screening[:id])

    # TODO: remove this once we can consistently have a fresh page for these specs
    page.driver.browser.navigate.refresh
  end

  def stub_and_visit_show_screening(screening)
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_relationships
    stub_empty_history_for_screening(screening)

    visit screening_path(id: screening[:id])

    # TODO: remove this once we can consistently have a fresh page for these specs
    page.driver.browser.navigate.refresh
  end

  def save_all_cards
    within('.card', text: 'Screening Information') { click_button 'Save' }
    within('.card', text: 'Narrative') { click_button 'Save' }
    within('.card', text: 'Incident Information') { click_button 'Save' }
    within('.card', text: 'Allegations') { click_button 'Save' }
    within('.card', text: 'Worker Safety') { click_button 'Save' }
    within('.card', text: 'Cross Report') { click_button 'Save' }
    within('.card', text: 'Decision') { click_button 'Save' }
  end

  def cancel_all_cards
    within('.card', text: 'Screening Information') { click_button 'Cancel' }
    within('.card', text: 'Narrative') { click_button 'Cancel' }
    within('.card', text: 'Incident Information') { click_button 'Cancel' }
    within('.card', text: 'Allegations') { click_button 'Cancel' }
    within('.card', text: 'Worker Safety') { click_button 'Cancel' }
    within('.card', text: 'Cross Report') { click_button 'Cancel' }
    within('.card', text: 'Decision') { click_button 'Cancel' }
  end
end

def assign_relationship(tag:, element_text:, link_text: 'Attach')
  within '#relationships-card.card .relationships' do
    find(tag, text: element_text)
      .find('a', text: link_text).click
  end
end

RSpec.configure do |config|
  config.include ScreeningHelpers, type: :feature
end
