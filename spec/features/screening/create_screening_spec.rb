# frozen_string_literal: true

require 'rails_helper'
require 'feature/testing'

feature 'Create Screening' do
  context 'when authentication is enabled' do
    let(:auth_validation_url) { 'http://www.example.com/authn/validate?token=123' }

    around do |example|
      with_config(
        authentication_base_url: 'http://www.example.com',
        base_path: ''
      ) do
        Feature.run_with_activated(:authentication) do
          example.run
        end
      end
    end

    context 'user has full name and staff Id' do
      let(:user_details) do
        {
          first_name: 'Joe',
          middle_initial: 'B',
          last_name: 'Cool',
          county: 'Mendocino',
          staff_id: '1234'
        }
      end
      let(:auth_details) { { staffId: '1234' } }

      scenario 'via start screening link' do
        user_name_display = 'Joe B. Cool - Mendocino'
        allow(LUID).to receive(:generate).and_return(['DQJIYK'])
        new_screening = {
          id: '1',
          reference: 'DQJIYK',
          assignee: user_name_display,
          assignee_staff_id: '1234',
          incident_county: nil,
          indexable: true,
          incident_address: {},
          addresses: [],
          cross_reports: [],
          participants: [],
          allegations: []
        }

        stub_empty_history_for_screening(new_screening)
        stub_empty_relationships
        stub_request(:post, ferb_api_url(FerbRoutes.intake_screenings_path))
          .with(body: new_screening.merge(incident_address: {}).as_json(except: :id))
          .and_return(json_body(new_screening.to_json, status: 201))

        stub_request(:get, ferb_api_url(FerbRoutes.screenings_path))
          .and_return(json_body([].to_json, status: 200))

        stub_request(
          :get, ferb_api_url(FerbRoutes.intake_screening_path(new_screening[:id]))
        ).and_return(json_body(new_screening.to_json, status: 200))

        stub_request(:get, auth_validation_url)
          .and_return(json_body(auth_details.to_json, status: 200))

        stub_request(:get, ferb_api_url(FerbRoutes.staff_path('1234')))
          .and_return(json_body(user_details.to_json, status: 200))

        visit root_path(token: 123)
        click_button 'Start Screening'

        within '.page-header-mast' do
          expect(page).to have_content("Screening #{new_screening[:id]}")
        end

        expect(page).to have_field(
          'Assigned Social Worker',
          with: user_name_display,
          disabled: true
        )
      end
    end

    context 'incident information county uses userInfo county' do
      let(:user_details) do
        {
          first_name: 'Joe',
          middle_initial: 'B',
          last_name: 'Cool',
          county: 'Mendocino',
          county_code: '23',
          staff_id: '1234'
        }
      end
      let(:auth_details) { { staffId: '1234' } }

      scenario 'via start screening link' do
        user_name_display = 'Joe B. Cool - Mendocino'
        allow(LUID).to receive(:generate).and_return(['DQJIYK'])
        new_screening = {
          id: '1',
          reference: 'DQJIYK',
          assignee: user_name_display,
          assignee_staff_id: '1234',
          incident_county: '23',
          indexable: true,
          incident_address: {},
          addresses: [],
          cross_reports: [],
          participants: [],
          allegations: []
        }

        stub_empty_history_for_screening(new_screening)
        stub_empty_relationships
        stub_request(:post, ferb_api_url(FerbRoutes.intake_screenings_path))
          .with(body: new_screening.merge(incident_address: {}).as_json(except: :id))
          .and_return(json_body(new_screening.to_json, status: 201))

        stub_request(:get, ferb_api_url(FerbRoutes.screenings_path))
          .and_return(json_body([].to_json, status: 200))

        stub_request(
          :get, ferb_api_url(FerbRoutes.intake_screening_path(new_screening[:id]))
        ).and_return(json_body(new_screening.to_json, status: 200))

        stub_request(:get, auth_validation_url)
          .and_return(json_body(auth_details.to_json, status: 200))

        stub_request(:get, ferb_api_url(FerbRoutes.staff_path('1234')))
          .and_return(json_body(user_details.to_json, status: 200))

        visit root_path(token: 123)
        click_button 'Start Screening'

        within '.page-header-mast' do
          expect(page).to have_content("Screening #{new_screening[:id]}")
        end

        expect(page).to have_select('Incident County', selected: 'Mendocino', disabled: true)

        within '#incident-information-card' do
          click_button 'Cancel'
          expect(page).to have_content('Mendocino')
        end
      end
    end

    context 'user has first and last name' do
      let(:user_details) do
        {
          first_name: 'Joe',
          last_name: 'Cool',
          county: 'Mendocino',
          staff_id: '1234'
        }
      end
      let(:auth_details) { { staffId: '1234' } }

      scenario 'via start screening link' do
        user_name_display = 'Joe Cool - Mendocino'
        allow(LUID).to receive(:generate).and_return(['DQJIYK'])
        new_screening = {
          id: '1',
          reference: 'DQJIYK',
          assignee: user_name_display,
          assignee_staff_id: '1234',
          incident_county: nil,
          indexable: true,
          incident_address: {},
          addresses: [],
          cross_reports: [],
          participants: [],
          allegations: []
        }
        stub_empty_history_for_screening(new_screening)
        stub_empty_relationships
        stub_request(:post, ferb_api_url(FerbRoutes.intake_screenings_path))
          .with(body: new_screening.merge(incident_address: {}).as_json(except: :id))
          .and_return(json_body(new_screening.to_json, status: 201))

        stub_request(:get, ferb_api_url(FerbRoutes.screenings_path))
          .and_return(json_body([].to_json, status: 200))

        stub_request(
          :get, ferb_api_url(FerbRoutes.intake_screening_path(new_screening[:id]))
        ).and_return(json_body(new_screening.to_json, status: 200))
        stub_request(:get, auth_validation_url)
          .and_return(json_body(auth_details.to_json, status: 200))
        stub_request(:get, ferb_api_url(FerbRoutes.staff_path('1234')))
          .and_return(json_body(user_details.to_json, status: 200))

        visit root_path(token: 123)
        click_button 'Start Screening'

        within '.page-header-mast' do
          expect(page).to have_content("Screening #{new_screening[:id]}")
        end

        expect(page).to have_field(
          'Assigned Social Worker',
          with: user_name_display,
          disabled: true
        )
      end
    end

    context 'no user information' do
      scenario 'via start screening link' do
        allow(LUID).to receive(:generate).and_return(['DQJIYK'])
        new_screening = {
          id: '1',
          reference: 'DQJIYK',
          assignee: nil,
          assignee_staff_id: nil,
          incident_county: nil,
          indexable: true,
          incident_address: {},
          addresses: [],
          cross_reports: [],
          participants: [],
          allegations: []
        }
        stub_empty_history_for_screening(new_screening)
        stub_empty_relationships
        stub_request(:post, ferb_api_url(FerbRoutes.intake_screenings_path))
          .with(body: new_screening.merge(incident_address: {}).as_json(except: :id))
          .and_return(json_body(new_screening.to_json, status: 201))

        stub_request(:get, ferb_api_url(FerbRoutes.screenings_path))
          .and_return(json_body([].to_json, status: 200))

        stub_request(
          :get, ferb_api_url(FerbRoutes.intake_screening_path(new_screening[:id]))
        ).and_return(json_body(new_screening.to_json, status: 200))

        stub_request(:get, auth_validation_url)
          .and_return(status: 200)

        visit root_path(token: 123)
        click_button 'Start Screening'

        within '.page-header-mast' do
          expect(page).to have_content("Screening #{new_screening[:id]}")
        end

        expect(page).to have_field('Assigned Social Worker', with: '', disabled: false)
      end
    end
  end

  scenario 'via start screening link' do
    allow(LUID).to receive(:generate).and_return(['DQJIYK'])
    new_screening = {
      id: '1',
      reference: 'DQJIYK',
      assignee: nil,
      assignee_staff_id: nil,
      incident_county: nil,
      indexable: true,
      incident_address: {},
      addresses: [],
      cross_reports: [],
      participants: [],
      allegations: []
    }

    stub_empty_history_for_screening(new_screening)
    stub_empty_relationships
    stub_request(:post, ferb_api_url(FerbRoutes.intake_screenings_path))
      .with(body: new_screening.merge(incident_address: {}).as_json(except: :id))
      .and_return(json_body(new_screening.to_json, status: 201))

    stub_request(:get, ferb_api_url(FerbRoutes.screenings_path))
      .and_return(json_body([].to_json, status: 200))

    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(new_screening[:id])))
      .and_return(json_body(new_screening.to_json, status: 200))

    visit root_path
    click_button 'Start Screening'

    expect(
      a_request(
        :post, ferb_api_url(FerbRoutes.intake_screenings_path)
      ).with(body: new_screening.merge(incident_address: {}).as_json(except: :id))
    ).to have_been_made

    within '.page-header-mast' do
      expect(page).to have_content("Screening #{new_screening[:id]}")
    end
  end
end
