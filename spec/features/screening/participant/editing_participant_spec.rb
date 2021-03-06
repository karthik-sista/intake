# frozen_string_literal: true

require 'rails_helper'

feature 'Edit Person' do
  let(:new_ssn) { '123-23-1234' }
  let(:old_ssn) { '555-56-7895' }
  let(:marge_roles) { %w[Victim Perpetrator] }
  let(:phone_number) { FactoryBot.create(:phone_number, number: '1234567890', type: 'Work') }
  let(:marge) do
    FactoryBot.create(
      :participant,
      :with_complete_address,
      phone_numbers: [phone_number],
      middle_name: 'Jacqueline',
      name_suffix: 'sr',
      ssn: old_ssn,
      sealed: false,
      sensitive: true,
      races: [
        { race: 'Asian', race_detail: 'Hmong' }
      ],
      roles: marge_roles,
      languages: ['Russian'],
      ethnicity: {
        hispanic_latino_origin: 'Yes',
        ethnicity_detail: ['Mexican']
      }
    )
  end
  let(:marge_formatted_name) do
    "#{marge.first_name} #{marge.middle_name} #{marge.last_name}, #{marge.name_suffix.humanize}"
  end
  let(:homer) { FactoryBot.create(:participant, :with_complete_address, ssn: nil) }
  let(:screening) do
    {
      id: '1',
      cross_reports: [],
      allegations: [],
      incident_address: {},
      safety_alerts: [],
      participants: [marge.as_json.symbolize_keys, homer.as_json.symbolize_keys]
    }
  end

  before do
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships
    marge.screening_id = screening[:id]
    homer.screening_id = screening[:id]
  end

  scenario 'character limitations by field' do
    visit edit_screening_path(id: screening[:id])
    within edit_participant_card_selector(marge.id) do
      fill_in 'Zip', with: '9i5%6Y1 8-_3.6+9*7='
      expect(page).to have_field('Zip', with: '95618')
      fill_in 'Zip', with: '9i5%6Y1 8'
      expect(page).to have_field('Zip', with: '95618')
    end
  end

  context 'editing and saving basic person information' do
    scenario 'saves the person information' do
      stub_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
        .and_return(json_body(marge.to_json, status: 200))
      visit edit_screening_path(id: screening[:id])
      within edit_participant_card_selector(marge.id) do
        within '.card-header' do
          expect(page).to have_content('Sensitive')
          expect(page).to have_content marge_formatted_name
          expect(page).to have_button 'Remove person'
        end
        within '.card-body' do
          table_description = marge.legacy_descriptor.legacy_table_description
          ui_id = marge.legacy_descriptor.legacy_ui_id
          expect(page).to have_react_select_field 'Role', with: %w[Victim Perpetrator]
          expect(page).to have_content("#{table_description} ID #{ui_id} in CWS-CMS")
          expect(page).to have_field('First Name', with: marge.first_name)
          expect(page).to have_field('Middle Name', with: marge.middle_name)
          expect(page).to have_field('Last Name', with: marge.last_name)
          expect(page).to have_field('Suffix', with: marge.name_suffix)
          expect(page).to have_field('Social security number', with: marge.ssn)

          fill_in 'First Name', with: ''
          fill_in 'First Name', with: 'new first name'
          fill_in 'Middle Name', with: ''
          fill_in 'Middle Name', with: 'new middle name'
          fill_in 'Last Name', with: ''
          fill_in 'Last Name', with: 'new last name'
          fill_in 'Social security number', with: ''
          fill_in 'Social security number', with: 111_111_111
          select 'Sr', from: 'Suffix'
        end
        click_button 'Save'
      end

      expect(
        a_request(:put,
          ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
        .with(
          body: hash_including(
            first_name: 'new first name',
            middle_name: 'new middle name',
            last_name: 'new last name',
            name_suffix: 'sr',
            ssn: '111-11-1111'
          )
        )
      ).to have_been_made
    end
  end

  context 'editing and saving person phone numbers' do
    scenario 'saves the person information' do
      stub_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
        .and_return(json_body({}.to_json, status: 200))

      visit edit_screening_path(id: screening[:id])
      within edit_participant_card_selector(marge.id) do
        within '.card-body' do
          expect(page).to have_field('Phone Number', with: '(123)456-7890')
          expect(page).to have_field('Phone Number Type', with: phone_number.type)

          click_button 'Add new phone number'

          within all('.row.list-item')[1] do
            fill_in 'Phone Number', with: '9876543210'
            select 'Cell', from: 'Phone Number Type'
          end
        end
        click_button 'Save'
      end

      expect(
        a_request(:put,
          ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
        .with(
          body: hash_including(
            'phone_numbers' => array_including(
              hash_including(
                'id' => phone_number.id,
                'number' => phone_number.number,
                'type' => phone_number.type
              ),
              hash_including(
                'id' => nil,
                'number' => '(987)654-3210',
                'type' => 'Cell'
              )
            )
          )
        )
      ).to have_been_made
    end
  end

  context 'editing and saving addresses' do
    scenario 'saves the person information' do
      stub_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], homer.id)))
        .and_return(json_body({}.to_json, status: 200))

      address = homer.addresses.first
      visit edit_screening_path(id: screening[:id])
      within edit_participant_card_selector(homer.id) do
        within '.card-body' do
          expect(page).to have_field('Address', with: address.street_address)
          expect(page).to have_field('City', with: address.city)
          expect(page).to have_field('State', with: address.state)
          expect(page).to have_field('Zip', with: address.zip)
          expect(find_field('Address Type').value).to eq(address.type)

          click_button 'Add new address'

          within all('.row.list-item').last do
            fill_in 'Address', with: '1234 Some Lane'
            fill_in 'City', with: 'Someplace'
            select 'California', from: 'State'
            fill_in 'Zip', with: '55555'
            select 'Home', from: 'Address Type'
          end
        end
        click_button 'Save'
      end

      expect(
        a_request(:put,
          ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], homer.id)))
        .with(
          body: hash_including(
            'addresses' => array_including(
              hash_including(
                'id' => address.id,
                'street_address' => address.street_address,
                'city' => address.city,
                'state' => address.state,
                'zip' => address.zip,
                'type' => address.type
              ),
              hash_including(
                'id' => nil,
                'street_address' => '1234 Some Lane',
                'city' => 'Someplace',
                'state' => 'CA',
                'zip' => '55555',
                'type' => 'Home'
              )
            )
          )
        )
      ).to have_been_made
    end
  end

  context 'editing and saving person demographics' do
    scenario 'saves the person information' do
      stub_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
        .and_return(json_body({}.to_json, status: 200))

      visit edit_screening_path(id: screening[:id])
      dob = Time.parse(marge.date_of_birth).strftime('%m/%d/%Y')
      within edit_participant_card_selector(marge.id) do
        within '.card-body' do
          expect(page).to have_field('Date of birth', with: dob)
          expect(page).to have_field('Approximate Age', disabled: true)
          expect(page).to have_field('Approximate Age Units', disabled: true)
          expect(page).to have_field('Sex at Birth', with: marge.gender)
          expect(page).to have_react_select_field(
            'Language(s) (Primary First)', with: marge.languages
          )
        end
        click_button 'Save'
      end

      expect(
        a_request(:put,
          ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
        .with(
          body: hash_including(
            date_of_birth: marge.date_of_birth,
            gender: marge.gender,
            languages: marge.languages
          )
        )
      ).to have_been_made
    end
  end

  scenario 'editing & saving a person for a screening saves only the relevant person ids' do
    stub_request(:put,
      ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
      .and_return(json_body({}.to_json, status: 200))

    visit edit_screening_path(id: screening[:id])

    within edit_participant_card_selector(marge.id) do
      click_button 'Save'
    end

    expect(
      a_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
      .with(
        body: hash_including(
          screening_id: screening[:id],
          sensitive: true,
          sealed: false,
          legacy_descriptor: hash_including(
            'id' => marge.legacy_descriptor.id,
            'legacy_id' => marge.legacy_descriptor.legacy_id,
            'legacy_last_updated' => marge.legacy_descriptor.legacy_last_updated.iso8601(3),
            'legacy_table_description' => marge.legacy_descriptor.legacy_table_description,
            'legacy_table_name' => marge.legacy_descriptor.legacy_table_name,
            'legacy_ui_id' => marge.legacy_descriptor.legacy_ui_id
          )
        )
      )
    ).to have_been_made
  end

  scenario 'editing and saving a participant for a screening saves only the relevant participant' do
    visit edit_screening_path(id: screening[:id])
    within edit_participant_card_selector(marge.id) do
      within '.card-header' do
        expect(page).to have_content('Sensitive')
        expect(page).to have_content marge_formatted_name
        expect(page).to have_button 'Remove person'
      end

      within '.card-body' do
        table_description = marge.legacy_descriptor.legacy_table_description
        ui_id = marge.legacy_descriptor.legacy_ui_id
        expect(page).to have_content("#{table_description} ID #{ui_id} in CWS-CMS")
        expect(page).to have_field('Phone Number', with: '(123)456-7890')
        expect(page).to have_field('Phone Number Type', with: 'Work')
        expect(page).to have_field('Sex at Birth', with: marge.gender)
        expect(page).to have_react_select_field(
          'Language(s) (Primary First)', with: marge.languages
        )
        # Date of birth should not have datepicker, but limiting by field ID will break when
        # DOB fields are correctly namespaced by participant ID. Feel free to make this more
        # specific once that's done.
        expect(page).not_to have_selector('.rw-select')
        dob = Time.parse(marge.date_of_birth).strftime('%m/%d/%Y')
        expect(page).to have_field('Date of birth', with: dob)
        expect(page).to have_field('Address', with: marge.addresses.first.street_address)
        expect(page).to have_field('City', with: marge.addresses.first.city)
        expect(page).to have_field('State', with: marge.addresses.first.state)
        expect(page).to have_field('Zip', with: marge.addresses.first.zip)
        expect(find_field('Address Type').value).to eq(marge.addresses.first.type)
        within '#ethnicity' do
          expect(page.find('input[value="Yes"]')).to be_checked
          expect(page).to have_field("participant-#{marge.id}-ethnicity-detail", text: 'Mexican')
        end
        within '#race' do
          expect(page.find('input[value="Asian"]')).to be_checked
          expect(page).to have_field("participant-#{marge.id}-Asian-race-detail", text: 'Hmong')
        end
        expect(page).to have_button 'Cancel'
        expect(page).to have_button 'Save'
        fill_in 'Social security number', with: new_ssn
        fill_in 'City', with: 'New City'
      end

      marge.ssn = new_ssn
      marge.addresses.first.city = 'New City'

      stub_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
        .and_return(json_body(marge.to_json, status: 200))
    end

    within edit_participant_card_selector(homer.id) do
      within '.card-body' do
        fill_in 'First Name', with: 'My new first name'
      end
    end

    within edit_participant_card_selector(marge.id) do
      within '.card-body' do
        click_button 'Save'
      end
      expect(
        a_request(:put,
          ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
      ).to have_been_made
    end

    within show_participant_card_selector(marge.id) do
      within '.card-body' do
        expect(page).to have_content(new_ssn)
        expect(page).to_not have_content(old_ssn)
        expect(page).to have_content('New City')
        expect(page).to_not have_content('Springfield')
      end
    end

    within edit_participant_card_selector(homer.id) do
      within '.card-body' do
        expect(page).to have_field('First Name', with: 'My new first name')
      end
    end
  end

  context 'editing social security number (ssn)' do
    scenario 'numbers are formatted correctly' do
      visit edit_screening_path(id: screening[:id])
      within edit_participant_card_selector(homer.id) do
        within '.card-body' do
          fill_in 'Social security number', with: ''
          expect(page).to have_field('Social security number', with: '')
          fill_in 'Social security number', with: 1
          expect(page).to have_field('Social security number', with: '1__-__-____')
          fill_in 'Social security number', with: 123_456_789
          expect(page).to have_field('Social security number', with: '123-45-6789')
        end
      end
    end

    scenario 'an invalid character is inserted' do
      visit edit_screening_path(id: screening[:id])
      within edit_participant_card_selector(homer.id) do
        within '.card-body' do
          fill_in 'Social security number', with: '12k34?!#adf567890'
          expect(page).to have_field('Social security number', with: '123-45-6789')
        end
      end
    end
  end

  scenario 'removing an address from a participant' do
    visit edit_screening_path(id: screening[:id])

    within edit_participant_card_selector(marge.id) do
      within '.card-body' do
        within page.all('.list-item').last do
          expect(page).to have_field('Address', with: marge.addresses.first.street_address)
          expect(page).to have_field('City', with: marge.addresses.first.city)
          expect(page).to have_field('State', with: marge.addresses.first.state)
          expect(page).to have_field('Zip', with: marge.addresses.first.zip)
          expect(find_field('Address Type').value).to eq(marge.addresses.first.type)
          click_link 'Delete address'
        end

        expect(page).to_not have_field('City', with: 'New City')
      end
    end

    marge.addresses = []
    stub_request(:put,
      ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
      .and_return(json_body(marge.to_json, status: 200))

    within edit_participant_card_selector(marge.id) do
      click_button 'Save'
    end

    expect(
      a_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
      .with(body: hash_including(addresses: []))
    ).to have_been_made
  end

  scenario 'when a user modifies languages for an existing participant' do
    visit edit_screening_path(id: screening[:id])

    within edit_participant_card_selector(marge.id) do
      within('.col-md-12', text: 'Language(s)') do
        fill_in_react_select 'Language(s)', with: 'English'
        fill_in_react_select 'Language(s)', with: 'Farsi'
        remove_react_select_option('Language(s)', marge.languages.first)
        fill_in_react_select 'Language(s)', with: 'Arabic'
        fill_in_react_select 'Language(s)', with: 'Spanish'
      end
      marge.languages = %w[English Arabic]
      stub_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
        .and_return(json_body(marge.to_json, status: 200))

      click_button 'Save'
      expect(a_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
        .with(body: hash_including(
          languages: contain_exactly('English', 'Arabic')
        ))).to have_been_made
    end
  end

  scenario 'when a user tabs out of the language multi-select' do
    visit edit_screening_path(id: screening[:id])

    within edit_participant_card_selector(marge.id) do
      within('.col-md-12', text: 'Language(s)') do
        fill_in_react_select 'Language(s)', with: 'English', exit_key: :tab
        expect(page).to have_react_select_field 'Language(s)', with: ['Russian']
      end
    end
  end

  scenario 'canceling edits for a screening participant' do
    visit edit_screening_path(id: screening[:id])
    within edit_participant_card_selector(marge.id) do
      within '.card-body' do
        expect(page).to have_field('Social security number', with: old_ssn)
        fill_in 'Social security number', with: new_ssn
        expect(page).to have_field('Social security number', with: new_ssn)
        click_button 'Cancel'
      end
    end

    expect(
      a_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
    ).to_not have_been_made

    within show_participant_card_selector(marge.id) do
      within '.card-body' do
        expect(page).to have_content(old_ssn)
        expect(page).to_not have_content(new_ssn)
      end
    end
  end

  scenario 'when a user clicks cancel on edit page' do
    visit edit_screening_path(id: screening[:id])

    within edit_participant_card_selector(marge.id) do
      fill_in 'Social security number', with: new_ssn
      click_button 'Cancel'
    end

    expect(page).to have_content marge_formatted_name
    expect(page).to have_link 'Edit person'
    expect(page).to have_content old_ssn
  end

  scenario 'when a user edits a participants role in a screening' do
    visit edit_screening_path(id: screening[:id])

    within edit_participant_card_selector(marge.id) do
      expect(page).to have_react_select_field('Role', with: %w[Victim Perpetrator])
      remove_react_select_option('Role', 'Perpetrator')
      expect(page).to have_no_content('Perpetrator')

      stub_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
        .and_return(json_body(marge.to_json, status: 200))

      within '.card-body' do
        click_button 'Save'
      end
    end

    expect(
      a_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
      .with(body: hash_including('roles' => ['Victim']))
    ).to have_been_made

    expect(page).to have_selector(show_participant_card_selector(marge.id))
  end

  scenario 'when a user tabs out of the role multi-select' do
    visit edit_screening_path(id: screening[:id])

    within edit_participant_card_selector(marge.id) do
      fill_in_react_select 'Role', with: 'Mandated Reporter', exit_key: :tab
      expect(page).to have_react_select_field 'Role', with: %w[Victim Perpetrator]
    end
  end

  context 'A participant has an existing reporter role' do
    let(:marge_roles) { ['Mandated Reporter'] }

    scenario 'the other reporter roles are unavailable' do
      visit edit_screening_path(id: screening[:id])

      within edit_participant_card_selector(marge.id) do
        fill_in_react_select('Role', with: 'Non-mandated Reporter')
        expect(page).to have_react_select_field('Role', with: ['Mandated Reporter'])

        remove_react_select_option('Role', 'Mandated Reporter')
        fill_in_react_select('Role', with: 'Non-mandated Reporter')
        expect(page).to have_react_select_field('Role', with: ['Non-mandated Reporter'])
      end
    end
  end

  scenario 'when a user modifies existing person ethnicity from Yes to nothing selected' do
    visit edit_screening_path(id: screening[:id])

    marge.ethnicity = { hispanic_latino_origin: nil, ethnicity_detail: [] }
    stub_request(:put,
      ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
      .and_return(json_body(marge.to_json, status: 200))

    within edit_participant_card_selector(marge.id) do
      within 'fieldset', text: 'Hispanic/Latino Origin' do
        find('label', text: 'Yes').click
      end

      click_button 'Save'
    end

    expect(
      a_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
      .with(body: hash_including(
        'ethnicity' => hash_including(
          'ethnicity_detail' => [],
          'hispanic_latino_origin' => nil
        )
      ))
    ).to have_been_made

    within show_participant_card_selector(marge.id) do
      expect(page).to_not have_content('Mexican - Yes')
    end
  end

  scenario 'setting an approximate age' do
    stub_request(:put,
      ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
      .and_return(json_body(marge.to_json, status: 201))

    visit edit_screening_path(id: screening[:id])
    within edit_participant_card_selector(marge.id) do
      expect(page).to have_field('Approximate Age', disabled: true)
      expect(page).to have_field('Approximate Age Units', disabled: true)
      fill_in_datepicker 'Date of birth', with: ''
      expect(page).to have_field('Approximate Age', disabled: false)
      expect(page).to have_field('Approximate Age Units', disabled: false)

      fill_in 'Approximate Age', with: 'abc1234'
      select 'Days', from: 'Approximate Age Units'
      expect(page).to have_field('Approximate Age', with: '123')
      expect(page).to have_select('Approximate Age Units', selected: 'Days')

      dob = Time.parse(marge.date_of_birth).strftime('%m/%d/%Y')
      fill_in_datepicker 'Date of birth', with: dob
      expect(page).to have_field('Approximate Age', disabled: true, with: '')
      expect(page).to have_select('Approximate Age Units', disabled: true, selected: '')

      fill_in_datepicker 'Date of birth', with: ''
      fill_in 'Approximate Age', with: 'abc1234'
      select 'Days', from: 'Approximate Age Units'
      fill_in_datepicker 'Date of birth', with: dob, blur: false
      click_button 'Save'
      expect(a_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
        .with(body: hash_including(
          date_of_birth: marge.date_of_birth,
          approximate_age: nil,
          approximate_age_units: nil
        ))).to have_been_made
    end
  end

  context 'saving a safely surrendered baby' do
    let(:screening) do
      {
        id: '1',
        report_type: 'ssb',
        cross_reports: [],
        allegations: [],
        incident_address: {},
        safety_alerts: [],
        participants: [homer.as_json.symbolize_keys]
      }
    end

    scenario 'updates the participant' do
      visit edit_screening_path(id: screening[:id])

      updated_participant = homer.as_json.merge(
        safelySurrenderedBabies: {
          surrendered_by: 'Unknown',
          relation_to_child: '1597',
          bracelet_id: '12345',
          parent_guardian_given_bracelet_id: 'A',
          parent_guardian_provided_med_questionaire: 'D',
          med_questionaire_return_date: '2011-01-01',
          comments: 'These are the comments.',
          participant_child: homer.id
        }
      )

      stub_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], homer.id)))
        .and_return(json_body(updated_participant.to_json, status: 200))

      within edit_participant_card_selector(homer.id) do
        expect(page).to have_no_content('Safely Surrendered Baby')

        fill_in_react_select('Role', with: 'Victim')

        expect(page).to have_content('Safely Surrendered Baby')

        within '.ssb-info' do
          fill_in_react_select 'Relationship to Surrendered Child', with: 'Grandmother'
          fill_in 'Bracelet ID', with: '12345'
          fill_in 'Comments', with: 'These are the comments.'
          fill_in_react_select 'Parent/Guardian Given Bracelet ID', with: 'Attempted'
          fill_in_react_select 'Parent/Guardian Provided Medical Questionaire', with: 'Declined'
          fill_in_datepicker 'Medical Questionaire Return Date', with: '01-01-2011'
        end
        click_button 'Save'
      end

      expect(a_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], homer.id)))
        .with(body: hash_including(
          safelySurrenderedBabies: anything
        ))).to have_been_made

      within show_participant_card_selector(homer.id) do
        expect(page).to have_content('Safely Surrendered Baby')
        expect(page).to have_content('Relationship to Surrendered Child Grandmother')
        expect(page).to have_content('Bracelet ID 12345')
        expect(page).to have_content('Parent/Guardian Given Bracelet ID Attempted')
        expect(page).to have_content('Parent/Guardian Provided Medical Questionaire Declined')
        expect(page).to have_content('Medical Questionaire Return Date 2011-01-01')
      end

      updated_screening = screening.as_json.merge(
        participants: [updated_participant.as_json.symbolize_keys]
      )

      stub_request(:get,
        ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
        .and_return(json_body(updated_screening.to_json, status: 200))

      visit edit_screening_path(id: screening[:id])

      within edit_participant_card_selector(homer.id) do
        expect(page).to have_content('Safely Surrendered Baby')
        expect(page).to have_select('relation-to-child', selected: 'Grandmother')
      end
    end
  end
end
