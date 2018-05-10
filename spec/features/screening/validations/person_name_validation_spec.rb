# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

feature 'Person Information Validations' do
  let(:screening) do
    {
      id: '1',
      incident_address: {},
      addresses: [],
      cross_reports: [],
      participants: [person.as_json.symbolize_keys],
      allegations: [],
      report_narrative: '',
      started_at: Time.new(2018, 12, 13)
    }
  end

  let(:person_name) { "#{person.first_name} #{person.last_name}" }

  before do
    stub_and_visit_edit_screening(screening)
  end

  context 'victim first name is not present' do
    let(:invalid_first_name) { nil }
    let(:valid_first_name) { 'John' }
    let(:person) do
      FactoryBot.create :participant,
        first_name: invalid_first_name,
        roles: ['Victim', 'Family Member']
    end
    let(:error_message) { 'Please enter a first name.' }

    scenario 'error is displayed until user enters a valid first name' do
      expect(page).to have_content person_name
      validate_message_as_user_interacts_with_person_card(
        person: person,
        error_message: error_message,
        person_updates: { first_name: valid_first_name }
      ) do
        within edit_participant_card_selector(person.id) do
          fill_in 'First Name', with: valid_first_name
        end
      end
    end

    scenario 'error is not displayed if the victim role is removed' do
      expect(page).to have_content person_name
      validate_message_as_user_interacts_with_person_card(
        person: person,
        error_message: error_message,
        person_updates: { roles: [] }
      ) do
        within edit_participant_card_selector(person.id) do
          remove_react_select_option('Role', 'Victim')
        end
      end
    end
  end

  context 'victim last name is not present' do
    let(:invalid_last_name) { nil }
    let(:valid_last_name) { 'Dow' }
    let(:person) do
      FactoryBot.create :participant,
        last_name: invalid_last_name,
        roles: ['Victim', 'Family Member']
    end
    let(:error_message) { 'Please enter a last name.' }

    scenario 'error is displayed until user enters a valid last name' do
      expect(page).to have_content person_name
      validate_message_as_user_interacts_with_person_card(
        person: person,
        error_message: error_message,
        person_updates: { last_name: valid_last_name }
      ) do
        within edit_participant_card_selector(person.id) do
          fill_in 'Last Name', with: valid_last_name
        end
      end
    end

    scenario 'error is not displayed if the victim role is removed' do
      expect(page).to have_content person_name
      validate_message_as_user_interacts_with_person_card(
        person: person,
        error_message: error_message,
        person_updates: { roles: [] }
      ) do
        within edit_participant_card_selector(person.id) do
          remove_react_select_option('Role', 'Victim')
        end
      end
    end
  end

  context 'collateral first name is not present' do
    let(:invalid_first_name) { nil }
    let(:valid_first_name) { 'John' }
    let(:person) do
      FactoryBot.create :participant,
        first_name: invalid_first_name,
        roles: ['Collateral', 'Family Member']
    end
    let(:error_message) { 'Please enter a first name.' }

    scenario 'error is displayed until user enters a valid first name' do
      expect(page).to have_content person_name
      validate_message_as_user_interacts_with_person_card(
        person: person,
        error_message: error_message,
        person_updates: { first_name: valid_first_name }
      ) do
        within edit_participant_card_selector(person.id) do
          fill_in 'First Name', with: valid_first_name
        end
      end
    end

    scenario 'error is not displayed if the victim role is removed' do
      expect(page).to have_content person_name
      validate_message_as_user_interacts_with_person_card(
        person: person,
        error_message: error_message,
        person_updates: { roles: [] }
      ) do
        within edit_participant_card_selector(person.id) do
          remove_react_select_option('Role', 'Collateral')
        end
      end
    end
  end

  context 'collateral last name is not present' do
    let(:invalid_last_name) { nil }
    let(:valid_last_name) { 'Dow' }
    let(:person) do
      FactoryBot.create :participant,
        last_name: invalid_last_name,
        roles: ['Collateral', 'Family Member']
    end
    let(:error_message) { 'Please enter a last name.' }

    scenario 'error is displayed until user enters a valid last name' do
      expect(page).to have_content person_name
      validate_message_as_user_interacts_with_person_card(
        person: person,
        error_message: error_message,
        person_updates: { last_name: valid_last_name }
      ) do
        within edit_participant_card_selector(person.id) do
          fill_in 'Last Name', with: valid_last_name
        end
      end
    end

    scenario 'error is not displayed if the victim role is removed' do
      expect(page).to have_content person_name
      validate_message_as_user_interacts_with_person_card(
        person: person,
        error_message: error_message,
        person_updates: { roles: [] }
      ) do
        within edit_participant_card_selector(person.id) do
          remove_react_select_option('Role', 'Collateral')
        end
      end
    end
  end
end
