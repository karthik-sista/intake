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

  context 'Age validation for Roles' do
    context 'Alleged victims age is not under 18 years based on approximate age with unit' do
      let(:invalid_date_of_birth) { nil }
      let(:invalid_approximate_age) { nil }
      let(:valid_approximate_age) { '96' }
      let(:invalid_approximate_age_units) { 'years' }
      let(:valid_approximate_age_units) { 'weeks' }
      let(:roles) { ['Victim'] }
      let(:person) do
        FactoryBot.create :participant,
          date_of_birth: invalid_date_of_birth,
          approximate_age: invalid_approximate_age,
          approximate_age_units: invalid_approximate_age_units,
          roles: roles
      end
      let(:error_message) { 'Alleged victims must be under 18 years old.' }

      context 'when roles does not include Victim' do
        let(:roles) { ['Family Member'] }

        scenario 'error not displayed even if approximate age is over 18 years' do
          stub_request(
            :put,
            intake_api_url(ExternalRoutes.intake_api_participant_path(person.id))
          ).and_return(json_body(person.to_json))

          within('.card.edit', text: person_name) { click_button 'Save' }

          within('.card.show', text: person_name) do
            expect(page).not_to have_content(error_message)
            click_link 'Edit'
          end

          within('.card.edit', text: person_name) do
            fill_in 'Approximate Age', with: valid_approximate_age
            expect(page).not_to have_content(error_message)
          end
        end
      end

      context 'when roles include victim' do
        let(:roles) { ['Victim', 'Family Member'] }

        scenario 'error is displayed until user enters a valid approximate age' do
          validate_message_as_user_interacts_with_person_card(
            person: person,
            error_message: error_message,
            person_updates: {
              approximate_age: valid_approximate_age,
              approximate_age_units: valid_approximate_age_units
            }
          ) do
            within edit_participant_card_selector(person.id) do
              fill_in 'Approximate Age', with: valid_approximate_age
              select valid_approximate_age_units.capitalize, from: 'approximate_age_units'
            end
          end
        end

        scenario 'error is not displayed if the victim role is removed' do
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

      scenario 'error is displayed until user enters a valid approximate age' do
        validate_message_as_user_interacts_with_person_card(
          person: person,
          error_message: error_message,
          person_updates: {
            approximate_age: valid_approximate_age,
            approximate_age_units: valid_approximate_age_units
          }
        ) do
          within edit_participant_card_selector(person.id) do
            fill_in 'Approximate Age', with: valid_approximate_age
            select valid_approximate_age_units.capitalize, from: 'approximate_age_units'
          end
        end
      end
    end

    context 'Alleged victims age is not under 18 years based on given date of birth' do
      let(:invalid_date_of_birth) { nil }
      let(:valid_date_of_birth) { Time.new(2002, 12, 13) }
      let(:roles) { ['Victim'] }
      let(:person) do
        FactoryBot.create :participant,
          date_of_birth: invalid_date_of_birth,
          roles: roles
      end
      let(:error_message) { 'Alleged victims must be under 18 years old.' }

      scenario 'error is displayed until user enters a valid date of birth' do
        validate_message_as_user_interacts_with_person_card(
          person: person,
          error_message: error_message,
          person_updates: { date_of_birth: valid_date_of_birth }
        ) do
          within edit_participant_card_selector(person.id) do
            fill_in_datepicker 'Date of birth', with: valid_date_of_birth
          end
        end
      end

      scenario 'validates error correctly even when the screeing date is changed' do
        validate_message_as_user_interacts_with_person_card(
          person: person,
          error_message: error_message,
          person_updates: { date_of_birth: valid_date_of_birth }
        ) do
          within edit_participant_card_selector(person.id) do
            fill_in_datepicker 'Date of birth', with: valid_date_of_birth
          end
          fill_in_datepicker 'Screening Start Date/Time', with: Time.new(2020, 1, 13)
        end
      end

      context 'when roles does not include Victim' do
        let(:roles) { ['Family Member'] }

        scenario 'error not displayed even if dob is over 18 years' do
          stub_request(
            :put,
            intake_api_url(ExternalRoutes.intake_api_participant_path(person.id))

          ).and_return(json_body(person.to_json))

          within('.card.edit', text: person_name) { click_button 'Save' }

          within('.card.show', text: person_name) do
            expect(page).not_to have_content(error_message)
            click_link 'Edit'
          end

          within('.card.edit', text: person_name) do
            fill_in_datepicker 'Date of birth', with: Time.new(1987, 12, 13)
            expect(page).not_to have_content(error_message)
          end
        end
      end

      context 'when roles include victim' do
        let(:roles) { ['Victim', 'Family Member'] }

        scenario 'error is displayed until user enters a valid date of birth' do
          validate_message_as_user_interacts_with_person_card(
            person: person,
            error_message: error_message,
            person_updates: { date_of_birth: valid_date_of_birth }
          ) do
            within edit_participant_card_selector(person.id) do
              fill_in_datepicker 'Date of birth', with: valid_date_of_birth
            end
          end
        end

        scenario 'error is not displayed if the victim role is removed' do
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
    end
  end
end
