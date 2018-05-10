# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

feature 'show cross reports' do
  scenario 'adding certain allegations makes certain cross reports required' do
    perpetrator = FactoryBot.create(
      :participant,
      :perpetrator
    )
    victim = FactoryBot.create(
      :participant,
      :victim
    )
    screening = {
      id: '1',
      incident_address: {},
      addresses: [],
      participants: [perpetrator.as_json.symbolize_keys, victim.as_json.symbolize_keys],
      allegations: [{
        id: '1',
        screening_id: '1',
        perpetrator_person_id: perpetrator.id,
        victim_person_id: victim.id,
        types: ['Severe neglect']
      }],
      cross_reports: [{
        id: '1',
        county_id: 'c41',
        agencies: [{ type: 'LAW_ENFORCEMENT', id: 'LAOFFCODE' }],
        method: 'Child Abuse Form'
      }]
    }
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships
    stub_county_agencies('c41')
    visit edit_screening_path(id: screening[:id])

    within '#cross-report-card.edit' do
      expect(page).to have_content('must be cross-reported to law enforcement')
      expect(page.find('label', text: /\ADistrict attorney\z/)[:class]).to include('required')
      expect(page.find('label', text: /\ALaw enforcement\z/)[:class]).to include('required')
      expect(page.find('label', text: 'Law enforcement agency name')[:class]).to include('required')
      expect(page.find('label', text: 'Cross Reported on Date')[:class]).to include('required')
      expect(page.find('label', text: 'Communication Method')[:class]).to include('required')
      click_button 'Cancel'
    end

    within '#cross-report-card.show' do
      expect(page).to have_content('must be cross-reported to law enforcement')
      expect(page.find('label', text: 'Cross Reported on Date')[:class]).to include('required')
      expect(page.find('label', text: 'Communication Method')[:class]).to include('required')
    end
  end

  scenario 'adding certain allegations does NOT make any cross reports required' do
    perpetrator = FactoryBot.create(
      :participant,
      :perpetrator
    )
    victim = FactoryBot.create(
      :participant,
      :victim
    )
    victim2 = FactoryBot.create(
      :participant,
      :victim
    )
    screening = {
      id: '1',
      incident_address: {},
      addresses: [],
      participants: [
        perpetrator.as_json.symbolize_keys,
        victim.as_json.symbolize_keys,
        victim2.as_json.symbolize_keys
      ],
      allegations: [{
        id: '1',
        screening_id: '1',
        perpetrator_person_id: perpetrator.id,
        victim_person_id: victim.id,
        types: ['General neglect']
      }, {
        id: '2',
        screening_id: 1,
        perpetrator_person_id: perpetrator.id,
        victim_person_id: victim2.id,
        types: ['At risk, sibling abused']
      }],
      cross_reports: [{
        id: '1',
        county_id: 'c41',
        agencies: [{ type: 'LAW_ENFORCEMENT', id: 'LAOFFCODE' }],
        method: 'Child Abuse Form'
      }]
    }
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships
    stub_county_agencies('c41')
    visit edit_screening_path(id: screening[:id])

    within '#cross-report-card.edit' do
      expect(page).to_not have_content('must be cross-reported to law enforcement')
      expect(page.find('label', text: /\ADistrict attorney\z/)[:class]).to_not include('required')
      expect(page.find('label', text: /\ALaw enforcement\z/)[:class]).to_not include('required')
      expect(page.find('label', text: 'Law enforcement agency name')[:class]).to include('required')
      expect(page.find('label', text: 'Cross Reported on Date')[:class]).to include('required')
      expect(page.find('label', text: 'Communication Method')[:class]).to include('required')
    end
  end

  scenario 'when allegations are required and user selects and unselects cross report options' do
    perpetrator = FactoryBot.create(
      :participant,
      :perpetrator
    )
    victim = FactoryBot.create(
      :participant,
      :victim
    )
    victim2 = FactoryBot.create(
      :participant,
      :victim
    )
    screening = {
      id: '1',
      incident_address: {},
      addresses: [],
      participants: [
        perpetrator.as_json.symbolize_keys,
        victim.as_json.symbolize_keys,
        victim2.as_json.symbolize_keys
      ],
      allegations: [{
        id: '1',
        screening_id: '1',
        perpetrator_person_id: perpetrator.id,
        victim_person_id: victim.id,
        types: ['Severe neglect']
      }, {
        id: '2',
        screening_id: 1,
        perpetrator_person_id: perpetrator.id,
        victim_person_id: victim2.id,
        types: ['At risk, sibling abused']
      }],
      cross_reports: []
    }
    stub_county_agencies('c41')
    stub_request(:get, ferb_api_url(FerbRoutes.intake_screening_path(screening[:id])))
      .and_return(json_body(screening.to_json, status: 200))
    stub_empty_history_for_screening(screening)
    stub_empty_relationships
    visit edit_screening_path(id: screening[:id])

    within '#cross-report-card.edit' do
      expect(page).to have_content('must be cross-reported to law enforcement')
      select 'State of California', from: 'County'
      find('label', text: /\ADistrict attorney\z/).click
      expect(page).to have_content('must be cross-reported to law enforcement')
      select 'LA District Attorney - Criminal Division', from: 'District attorney agency name'
      find('label', text: /\ALaw enforcement\z/).click
      expect(page).to_not have_content('must be cross-reported to law enforcement')
      select 'The Sheriff', from: 'Law enforcement agency name'
    end

    api_screening = screening.merge(address: {}, cross_reports: [{
                                      county_id: 'c41',
                                      agencies: [
                                        { type: 'DISTRICT_ATTORNEY', id: '65Hvp7x01F' },
                                        { type: 'LAW_ENFORCEMENT', id: 'BMG2f3J75C' }
                                      ]
                                    }])
    api_screening.delete(:incident_address)
    stub_request(:put, intake_api_url(ExternalRoutes.intake_api_screening_path(screening[:id])))
      .and_return(json_body(api_screening.to_json, status: 200))
    within '#cross-report-card.edit' do
      click_button 'Save'
    end

    within '#cross-report-card.show' do
      expect(page).to_not have_content('must be cross-reported to law enforcement')
    end
  end
end
