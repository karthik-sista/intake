# frozen_string_literal: true

require 'rails_helper'

feature 'Participant Address' do
  let(:marge) do
    {
      id: '1',
      first_name: 'Marge',
      last_name: 'Simpson',
      legacy_descriptor: {
        legacy_id: '1',
        legacy_source_table: 'ADDR_T'
      },
      addresses: [],
      phone_numbers: [],
      roles: []
    }
  end
  let(:screening) do
    {
      id: '1',
      incident_address: {},
      cross_reports: [],
      allegations: [],
      safety_alerts: [],
      participants: [marge]
    }
  end
  before do
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_relationships
    stub_empty_history_for_screening(screening)
  end

  scenario 'has read only addresses ' do
    visit edit_screening_path(id: screening[:id])
    expect(page).to_not have_field('Address', with: '1234 Some Lane')

    marge[:addresses].push(
      street_address: '1234 Some Lane',
      city: 'Someplace',
      state: 'CA',
      zip: '55555',
      type: 'Home'
    )
    stub_request(
      :put, ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge[:id]))
    ).and_return(json_body(marge.to_json, status: 200))

    within edit_participant_card_selector(marge[:id]) do
      click_button 'Add new address'

      expect(page).to have_select('Address Type', options: [
                                    '',
                                    'Common',
                                    'Day Care',
                                    'Home',
                                    'Homeless',
                                    'Other',
                                    'Penal Institution',
                                    'Permanent Mailing Address',
                                    'Residence 2',
                                    'Work'
                                  ])

      within all('.row.list-item').first do
        fill_in 'Address', with: '1234 Some Lane'
        fill_in 'City', with: 'Someplace'
        select 'California', from: 'State'
        fill_in 'Zip', with: '55555'
        select 'Home', from: 'Address Type'
      end

      click_button 'Save'
    end

    expect(a_request(:put,
      ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge[:id])))
               .with(body: hash_including(
                 'addresses' => array_including(
                   hash_including(
                     'id' => nil,
                     'street_address' => '1234 Some Lane',
                     'city' => 'Someplace',
                     'state' => 'CA',
                     'zip' => '55555',
                     'type' => 'Home',
                     'legacy_id' => nil
                   )
                 )
               ))).to have_been_made

    within show_participant_card_selector(marge[:id]) do
      click_link 'Edit'
      expect(page).to_not have_field('Address', with: marge[:addresses].first[:street_address])
      expect(page).to have_field('Address', with: '1234 Some Lane')
    end
  end
end
