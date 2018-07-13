# frozen_string_literal: true

require 'rails_helper'

feature 'edit allegations' do
  scenario 'loading screening with participants generates possible allegations' do
    marge = FactoryBot.create(
      :participant,
      :perpetrator,
      first_name: 'Marge',
      last_name: 'Simpson',
      date_of_birth: nil
    )
    homer = FactoryBot.create(
      :participant,
      :perpetrator,
      first_name: 'Homer',
      last_name: 'Simpson',
      date_of_birth: nil
    )

    bart = FactoryBot.create(
      :participant,
      first_name: 'Bart',
      last_name: 'Simpson',
      date_of_birth: nil,
      roles: %w[Victim Perpetrator]
    )

    lisa = FactoryBot.create(:participant, :victim,
      first_name: 'Lisa',
      last_name: 'Simpson',
      date_of_birth: nil)

    screening = {
      id: '1',
      incident_address: {},
      cross_reports: [],
      participants: [
        marge.as_json.symbolize_keys,
        homer.as_json.symbolize_keys,
        bart.as_json.symbolize_keys,
        lisa.as_json.symbolize_keys
      ],
      allegations: []
    }
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships

    visit edit_screening_path(id: screening[:id])

    within '.card.edit', text: 'Allegations' do
      within('tbody') do
        table_rows = page.all('tr')
        expect(table_rows.count).to eq(5)

        within(table_rows[0]) do
          expect(page).to have_content('Bart')
          expect(page).to have_content('Homer')
          expect(page).to have_react_select_field("allegations_#{bart.id}_#{homer.id}", with: [])
        end

        within(table_rows[1]) do
          expect(page).to have_no_content('Bart')
          expect(page).to have_content('Marge')
          expect(page).to have_react_select_field("allegations_#{bart.id}_#{marge.id}", with: [])
        end

        within(table_rows[2]) do
          expect(page).to have_content('Lisa')
          expect(page).to have_content('Bart')
          expect(page).to have_react_select_field("allegations_#{lisa.id}_#{bart.id}", with: [])
        end

        within(table_rows[3]) do
          expect(page).to have_no_content('Lisa')
          expect(page).to have_content('Homer')
          expect(page).to have_react_select_field("allegations_#{lisa.id}_#{homer.id}", with: [])
        end

        within(table_rows[4]) do
          expect(page).to have_no_content('Lisa')
          expect(page).to have_content('Marge')
          expect(page).to have_react_select_field("allegations_#{lisa.id}_#{marge.id}", with: [])
        end
      end
    end
  end

  scenario 'removing participant role, re-adding it does not show deleted allegations' do
    marge = FactoryBot.create(
      :participant,
      first_name: 'Marge',
      roles: ['Perpetrator', 'Anonymous Reporter']
    )
    lisa = FactoryBot.create(:participant, :victim, first_name: 'Lisa', last_name: 'Simpson')
    screening = {
      id: '1',
      incident_address: {},
      cross_reports: [],
      participants: [marge.as_json.symbolize_keys, lisa.as_json.symbolize_keys],
      allegations: []
    }.as_json.symbolize_keys

    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships

    visit edit_screening_path(id: screening[:id])

    within '.card.edit', text: 'Allegations' do
      within 'tbody tr' do
        expect(page).to have_content('Marge')
        expect(page).to have_content('Lisa')
      end
      click_button 'Cancel'
    end

    marge.roles = ['Anonymous Reporter']
    stub_request(:put,
      ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
      .and_return(json_body(marge.to_json, status: 200))

    screening[:allegations] = []
    screening[:participants] = [lisa.as_json.symbolize_keys, marge.as_json.symbolize_keys]
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within edit_participant_card_selector(marge.id) do
      visit current_url + '#search-card'
      remove_react_select_option('Role', 'Perpetrator')
      page.execute_script 'window.scrollBy(0,1000)'
      click_button 'Save'
    end

    within '.card.show', text: 'Allegations' do
      within 'tbody', visible: false do
        expect(page).to_not have_content('Marge')
        expect(page).to_not have_content('Lisa')
      end
    end

    within show_participant_card_selector(marge.id) do
      visit current_url
      click_link 'Edit person'
    end

    marge[:roles] = ['Anonymous Reporter', 'Perpetrator']
    stub_request(:put,
      ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
      .and_return(json_body(marge.to_json, status: 200))

    screening[:participants] = [lisa.as_json.symbolize_keys, marge.as_json.symbolize_keys]
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within edit_participant_card_selector(marge.id) do
      fill_in_react_select('Role', with: 'Perpetrator')
      page.execute_script 'window.scrollBy(0,1000)'
      click_button 'Save'
    end

    within '.card.show', text: 'Allegations' do
      within 'tbody', visible: false do
        expect(page).to_not have_content('Marge')
        expect(page).to_not have_content('Lisa')
      end
    end
    click_link('Allegations')
    click_link 'Edit allegations'

    within '.card.edit', text: 'Allegations' do
      within 'tbody tr' do
        expect(page).to have_content('Marge')
        expect(page).to have_content('Lisa')
      end
    end
  end

  scenario 'changing the roles of participants creates new possible allegation rows' do
    marge = FactoryBot.create(:participant, first_name: 'Marge')
    lisa = FactoryBot.create(:participant, first_name: 'Lisa')
    screening = {
      id: '1',
      incident_address: {},
      cross_reports: [],
      participants: [marge.as_json.symbolize_keys, lisa.as_json.symbolize_keys],
      allegations: []
    }
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships

    visit edit_screening_path(id: screening[:id])

    within '.card.edit', text: 'Allegations' do
      within 'thead' do
        expect(page).to have_content('Alleged Victim/Children')
        expect(page).to have_content('Alleged Perpetrator')
        expect(page).to have_content('Allegation(s)')
      end

      expect(page).to have_no_selector('td')
    end

    within edit_participant_card_selector(marge.id) do
      fill_in_react_select('Role', with: 'Perpetrator')
      marge.roles = ['Perpetrator']
      stub_request(:put,
        ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
        .and_return(json_body(marge.to_json, status: 200))
      page.execute_script 'window.scrollBy(0,1000)'
      click_button 'Save'
    end

    within '.card.edit', text: 'Allegations' do
      expect(page).to have_no_selector('td')
    end

    lisa.roles = ['Victim']
    stub_request(:put, ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], lisa.id)))
      .and_return(json_body(lisa.to_json, status: 200))

    screening[:participants] = [marge.as_json.symbolize_keys, lisa.as_json.symbolize_keys]
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships

    within edit_participant_card_selector(lisa.id) do
      fill_in_react_select('Role', with: 'Victim')
      visit current_url + '#search-card'
      page.execute_script 'window.scrollBy(0,1500)'
      click_button 'Save'
    end

    within '.card.edit', text: 'Allegations' do
      within('tbody tr') do
        expect(page).to have_content('Lisa')
        expect(page).to have_content('Marge')
      end
    end
  end

  scenario 'deleting a perpetrator participant does not remove allegation' do
    marge = FactoryBot.create(:participant, :perpetrator, first_name: 'Marge')
    lisa = FactoryBot.create(:participant, :victim, first_name: 'Lisa')
    screening = {
      id: '1',
      incident_address: {},
      cross_reports: [],
      participants: [marge.as_json.symbolize_keys, lisa.as_json.symbolize_keys],
      allegations: []
    }
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships

    visit edit_screening_path(id: screening[:id])

    within '.card.edit', text: 'Allegations' do
      within('tbody tr') do
        expect(page).to have_content('Lisa')
        expect(page).to have_content('Marge')
      end
    end

    screening[:participants] = [lisa.as_json.symbolize_keys]
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within edit_participant_card_selector(marge.id) do
      stub_request(:delete,
        ferb_api_url(FerbRoutes.delete_screening_participant_path(screening[:id], marge.id)))
        .and_return(json_body(nil, status: 204))

      click_button 'Remove person'
    end

    within '.card.edit', text: 'Allegations' do
      within('table') do
        expect(page).to have_content('Lisa')
        expect(page).to have_no_content('Marge')
      end
    end
  end

  scenario 'edit and saving allegations' do
    marge = FactoryBot.create(:participant, :perpetrator, first_name: 'Marge')
    lisa = FactoryBot.create(:participant, :victim, first_name: 'Lisa')
    screening = {
      id: '1',
      incident_address: {},
      cross_reports: [],
      participants: [marge.as_json.symbolize_keys, lisa.as_json.symbolize_keys],
      allegations: []
    }
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships

    visit edit_screening_path(id: screening[:id])

    persisted_allegation = {
      id: nil,
      victim_person_id: lisa.id,
      perpetrator_person_id: marge.id,
      screening_id: screening[:id],
      types: ['General neglect']
    }
    screening[:allegations] << persisted_allegation

    stub_request(:put, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within '.card.edit', text: 'Allegations' do
      fill_in_react_select "allegations_#{lisa.id}_#{marge.id}", with: 'General neglect'
      fill_in_react_select "allegations_#{lisa.id}_#{marge.id}",
        with: 'Severe neglect', exit_key: :tab
      expect(page).to have_react_select_field(
        "allegations_#{lisa.id}_#{marge.id}", with: ['General neglect']
      )
      click_button 'Save'
    end

    expect(
      a_request(:put, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
        .with(body: hash_including(screening))
    ).to have_been_made

    within '.card.show', text: 'Allegations' do
      within 'table tbody tr' do
        expect(page).to have_content('Lisa')
        expect(page).to have_content('Marge')
        expect(page).to have_content('General neglect')
      end
    end
  end

  scenario 'cancel edits for new allegations' do
    marge = FactoryBot.create(:participant, :perpetrator, first_name: 'Marge')
    lisa = FactoryBot.create(:participant, :victim, first_name: 'Lisa')
    screening = {
      id: '1',
      incident_address: {},
      cross_reports: [],
      participants: [marge.as_json.symbolize_keys, lisa.as_json.symbolize_keys],
      allegations: []
    }
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships

    visit edit_screening_path(id: screening[:id])

    within '.card.edit', text: 'Allegations' do
      fill_in_react_select "allegations_#{lisa.id}_#{marge.id}", with: 'General neglect'
      click_button 'Cancel'
    end

    within '.card.show', text: 'Allegations' do
      within('table') do
        expect(page).to have_no_content('Lisa')
        expect(page).to have_no_content('Marge')
        expect(page).to have_no_content('General neglect')
      end
    end
  end

  scenario 'cancel edits for a persisted allegation' do
    marge = FactoryBot.create(:participant, :perpetrator, first_name: 'Marge')
    lisa = FactoryBot.create(:participant, :victim, first_name: 'Lisa')
    allegation = {
      id: '1',
      victim_person_id: lisa.id,
      perpetrator_person_id: marge.id,
      screening_id: '1',
      types: ['General neglect']
    }
    screening = {
      id: '1',
      incident_address: {},
      cross_reports: [],
      participants: [marge.as_json.symbolize_keys, lisa.as_json.symbolize_keys],
      allegations: [allegation]
    }

    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships

    visit edit_screening_path(id: screening[:id])

    within '.card.edit', text: 'Allegations' do
      fill_in_react_select "allegations_#{lisa.id}_#{marge.id}", with: 'Severe neglect'
      page.find('.card-header').click
      click_button 'Cancel'
    end

    within '.card.show', text: 'Allegations' do
      within('table') do
        expect(page).to have_content('Lisa')
        expect(page).to have_content('Marge')
        expect(page).to have_content('General neglect')
        expect(page).to_not have_content('Severe neglect')
      end
    end
  end

  scenario 'editing allegation types will not impact other allegations' do
    marge = FactoryBot.create(:participant, :perpetrator,
      first_name: 'Marge',
      last_name: 'Simpson',
      date_of_birth: nil)
    homer = FactoryBot.create(:participant, :perpetrator,
      first_name: 'Homer',
      last_name: 'Simpson',
      date_of_birth: nil)
    lisa = FactoryBot.create(:participant, :victim, first_name: 'Lisa', last_name: 'Simps')
    screening = {
      id: '1',
      incident_address: {},
      cross_reports: [],
      participants: [
        marge.as_json.symbolize_keys,
        lisa.as_json.symbolize_keys,
        homer.as_json.symbolize_keys
      ],
      allegations: []
    }
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships

    visit edit_screening_path(id: screening[:id])

    within '.card.edit', text: 'Allegations' do
      within 'tbody' do
        table_rows = page.all('tr')

        within(table_rows[0]) do
          fill_in_react_select "allegations_#{lisa.id}_#{homer.id}", with: 'General neglect'
          expect(page).to have_react_select_field(
            "allegations_#{lisa.id}_#{homer.id}", with: ['General neglect']
          )
        end

        within(table_rows[1]) do
          expect(page).to have_react_select_field "allegations_#{lisa.id}_#{marge.id}", with: []
        end
      end
    end
  end

  scenario 'I remove a participant for whom I have added allegation types' do
    marge = FactoryBot.create(:participant, :perpetrator,
      first_name: 'Marge',
      last_name: 'Simpson',
      date_of_birth: nil)
    homer = FactoryBot.create(:participant, :perpetrator,
      first_name: 'Homer',
      last_name: 'Simpson',
      date_of_birth: nil)
    lisa = FactoryBot.create(:participant, :victim, first_name: 'Lisa', last_name: 'Simps')
    screening = {
      id: '1',
      incident_address: {},
      cross_reports: [],
      participants: [
        marge.as_json.symbolize_keys,
        lisa.as_json.symbolize_keys,
        homer.as_json.symbolize_keys
      ],
      allegations: []
    }
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships

    visit edit_screening_path(id: screening[:id])

    within '.card.edit', text: 'Allegations' do
      within 'tbody' do
        table_rows = page.all('tr')
        within(table_rows[0]) do
          expect(page).to have_react_select_field "allegations_#{lisa.id}_#{homer.id}", with: []
        end

        within(table_rows[1]) do
          fill_in_react_select "allegations_#{lisa.id}_#{marge.id}", with: 'General neglect'
          expect(page).to have_react_select_field(
            "allegations_#{lisa.id}_#{marge.id}", with: ['General neglect']
          )
        end
      end
    end

    screening[:participants] = [lisa.as_json.symbolize_keys, homer.as_json.symbolize_keys]
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within edit_participant_card_selector(marge.id) do
      stub_request(:delete,
        ferb_api_url(FerbRoutes.delete_screening_participant_path(screening[:id], marge.id)))
        .and_return(json_body(nil, status: 204))
      visit current_url + '#search-card'
      click_button 'Remove person'
    end

    within '.card.edit', text: 'Allegations' do
      expect(page).to have_content('Lisa')
      expect(page).to have_content('Homer')
      expect(page).to_not have_content('Marge')
      expect(page).to_not have_content('General neglect')
    end
  end

  scenario 'I remove the victim role from a participant for whom I have edited allegations' do
    marge = FactoryBot.create(:participant, :perpetrator, first_name: 'Marge', last_name: 'Simps')
    lisa = FactoryBot.create(
      :participant,
      roles: ['Victim', 'Anonymous Reporter'],
      first_name: 'Lisa',
      last_name: 'Simps'
    )
    screening = {
      id: '1',
      incident_address: {},
      cross_reports: [],
      participants: [marge.as_json.symbolize_keys, lisa.as_json.symbolize_keys],
      allegations: []
    }

    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships

    visit edit_screening_path(id: screening[:id])
    persisted_allegation = {
      victim_person_id: lisa.id,
      perpetrator_person_id: marge.id,
      screening_id: screening[:id],
      types: ['General neglect']
    }

    screening[:allegations] << persisted_allegation

    stub_request(:put, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within '.card.edit', text: 'Allegations' do
      fill_in_react_select "allegations_#{lisa.id}_#{marge.id}", with: 'General neglect'
      click_button 'Save'
    end

    within '.card.show', text: 'Allegations' do
      expect(page).to have_content('Lisa')
      expect(page).to have_content('Marge')
      expect(page).to have_content('General neglect')
    end

    lisa.roles = ['Anonymous Reporter']
    stub_request(:put, ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], lisa.id)))
      .and_return(json_body(lisa.to_json, status: 200))

    screening[:allegations] = []
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within edit_participant_card_selector(lisa.id) do
      visit current_url
      remove_react_select_option('Role', 'Victim')
      page.execute_script 'window.scrollBy(0,700)'
      click_button 'Save'
    end

    within show_participant_card_selector(lisa.id) do
      visit current_url + "#participant-card-#{marge.id}"
      click_link 'Edit person'
    end
    within '.card.show', text: 'Allegations' do
      expect(page).to have_no_content('Lisa')
      expect(page).to have_no_content('Marge')
      expect(page).to have_no_content('General neglect')
      click_link 'Edit allegations'
    end

    within '.card.edit', text: 'Allegations' do
      expect(page).to have_no_content('Lisa')
      expect(page).to have_no_content('Marge')
      expect(page).to have_no_content('General neglect')
    end

    lisa.roles = ['Anonymous Reporter', 'Victim']
    stub_request(:put, ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], lisa.id)))
      .and_return(json_body(lisa.to_json, status: 200))
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within edit_participant_card_selector(lisa.id) do
      fill_in_react_select('Role', with: 'Victim')
      click_button 'Save'
    end

    within '.card.edit', text: 'Allegations' do
      expect(page).to have_content('Lisa')
      expect(page).to have_content('Marge')
      expect(page).to have_no_content('General neglect')
    end
  end

  scenario 'remove perpetrator role from participant with victim role does not remove allegation' do
    lisa = FactoryBot.create(:participant, :victim, first_name: 'Lisa', last_name: 'Simps')
    marge = FactoryBot.create(
      :participant,
      roles: ['Perpetrator', 'Anonymous Reporter'],
      first_name: 'Marge',
      last_name: 'Simps'
    )
    screening = {
      id: '1',
      incident_address: {},
      cross_reports: [],
      participants: [marge.as_json.symbolize_keys, lisa.as_json.symbolize_keys],
      allegations: []
    }

    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships

    visit edit_screening_path(id: screening[:id])
    persisted_allegation = {
      id: nil,
      victim_person_id: lisa.id,
      perpetrator_person_id: marge.id,
      screening_id: screening[:id],
      types: ['General neglect']
    }

    screening[:allegations] << persisted_allegation

    stub_request(:put, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within '.card.edit', text: 'Allegations' do
      fill_in_react_select "allegations_#{lisa.id}_#{marge.id}", with: 'General neglect'
      click_button 'Save'
    end

    within '.card.show', text: 'Allegations' do
      expect(page).to have_content('Lisa')
      expect(page).to have_content('Marge')
      expect(page).to have_content('General neglect')
    end

    marge.roles = ['Anonymous Reporter']
    stub_request(:put,
      ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
      .and_return(json_body(marge.to_json, status: 200))

    screening[:allegations] = []
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within edit_participant_card_selector(marge.id) do
      visit current_url + '#search-card'
      remove_react_select_option('Role', 'Perpetrator')
      page.execute_script 'window.scrollBy(0,1000)'
      click_button 'Save'
    end

    within show_participant_card_selector(marge.id) do
      visit current_url
      click_link 'Edit person'
    end

    within '.card.show', text: 'Allegations' do
      expect(page).to have_no_content('Lisa')
      expect(page).to have_no_content('Marge')
      expect(page).to have_no_content('General neglect')
    end
    click_link('Allegations')
    click_link 'Edit allegations'

    within '.card.edit', text: 'Allegations' do
      expect(page).to have_content('Lisa')
      expect(page).to have_no_content('Marge')
      expect(page).to have_no_content('General neglect')
    end

    marge.roles = ['Anonymous Reporter', 'Perpetrator']
    stub_request(:put,
      ferb_api_url(FerbRoutes.screening_participant_path(screening[:id], marge.id)))
      .and_return(json_body(marge.to_json, status: 200))
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within edit_participant_card_selector(marge.id) do
      fill_in_react_select('Role', with: 'Perpetrator')
      page.execute_script 'window.scrollBy(0,800)'
      click_button 'Save'
    end
    within '.card.edit', text: 'Allegations' do
      expect(page).to have_content('Lisa')
      expect(page).to have_content('Marge')
      expect(page).to have_no_content('General neglect')
    end
  end

  scenario 'saving another card will not persist changes to allegations' do
    marge = FactoryBot.create(:participant, :perpetrator, first_name: 'Marge')
    lisa = FactoryBot.create(:participant, :victim, first_name: 'Lisa')
    screening = {
      id: '1',
      incident_address: {},
      cross_reports: [],
      participants: [marge.as_json.symbolize_keys, lisa.as_json.symbolize_keys],
      allegations: []
    }
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships

    visit edit_screening_path(id: screening[:id])

    within '.card.edit', text: 'Allegations' do
      fill_in_react_select "allegations_#{lisa.id}_#{marge.id}", with: 'General neglect'
    end

    screening[:name] = 'Hello'
    stub_request(:put, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))

    within '#screening-information-card.card.edit' do
      fill_in 'Title/Name of Screening', with: 'Hello'
      click_button 'Save'
    end

    expect(
      a_request(:put, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
        .with(body: hash_including(allegations: []))
    ).to have_been_made
  end

  scenario 'only allegations with allegation types are sent to the API' do
    marge = FactoryBot.create(:participant, :perpetrator,
      first_name: 'Marge',
      last_name: 'Simpson',
      date_of_birth: nil)
    homer = FactoryBot.create(:participant, :perpetrator,
      first_name: 'Homer',
      last_name: 'Simpson',
      date_of_birth: nil)
    lisa = FactoryBot.create(:participant, :victim, first_name: 'Lisa', last_name: 'Simps')
    screening = {
      id: '1',
      incident_address: {},
      cross_reports: [],
      participants: [
        marge.as_json.symbolize_keys,
        homer.as_json.symbolize_keys,
        lisa.as_json.symbolize_keys
      ],
      allegations: []
    }

    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_request(:put, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body({}.to_json, status: 200))
    stub_empty_relationships
    stub_empty_history_for_screening(screening)

    visit edit_screening_path(id: screening[:id])

    within '.card.edit', text: 'Allegations' do
      within 'tbody' do
        table_rows = page.all('tr')

        within table_rows[0] do
          expect(page).to have_content('Lisa')
          expect(page).to have_content('Homer')

          select_field_id = "allegations_#{lisa.id}_#{homer.id}"
          expect(page).to have_react_select_field(select_field_id, with: [])
          fill_in_react_select(select_field_id, with: 'Exploitation')
        end

        within table_rows[1] do
          expect(page).to have_no_content('Lisa')
          expect(page).to have_content('Marge')
          expect(page).to have_react_select_field("allegations_#{lisa.id}_#{marge.id}", with: [])
        end
      end
      click_button 'Save'
    end

    persisted_allegation = {
      id: nil,
      victim_person_id: lisa.id,
      perpetrator_person_id: homer.id,
      screening_id: screening[:id],
      types: ['Exploitation']
    }

    expect(
      a_request(:put, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .with(body: hash_including(allegations: [persisted_allegation]))
    ).to have_been_made
  end
end
