# frozen_string_literal: true

require 'rails_helper'

feature 'cross reports' do
  let(:existing_screening) do
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

  before do
    stub_county_agencies('c40')
    stub_county_agencies('c41')
    stub_county_agencies('c42')
  end

  scenario 'adding cross reports to an existing screening' do
    stub_request(
      :get, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_request(
      :put, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)
    visit edit_screening_path(id: existing_screening[:id])

    reported_on = DateTime.strptime('5/11/2018 11:10 AM', '%m/%d/%Y %l:%M %p')
    communication_method = 'Electronic Report'
    expect(page).to_not have_content 'Communication Time and Method'
    expect(page).to have_content 'County'
    select 'Sacramento', from: 'County'
    click_link('Cross Report')
    find('label', text: /\ACounty Licensing\z/).click
    select 'Hoverment Agency', from: 'County Licensing Agency Name'
    find('label', text: /\ALaw Enforcement\z/).click
    select 'The Sheriff', from: 'Law Enforcement Agency Name'
    expect(page).to have_content 'Communication Time and Method'
    fill_in_datepicker 'Cross Reported on Date', with: reported_on.strftime('%m/%d/%Y %l:%M %p')
    expect(find_field('Cross Reported on Date').value).to \
      eq(reported_on.strftime('%m/%d/%Y %l:%M %p'))
    within '#cross-report-card' do
      select communication_method, from: 'Communication Method'
    end
    click_link 'Cross Report'
    page.execute_script 'window.scrollBy(0,500)'
    page.find(:xpath, '//*[@id="cross-report-card"]/div[2]/div[5]/div/div/button[2]').click
    expect(
      a_request(
        :put, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
      ).with(
        body: hash_including(
          'cross_reports' => array_including(
            hash_including(
              'county_id' => 'c42',
              'agencies' => array_including(
                hash_including('code' => 'BMG2f3J75C', 'type' => 'LAW_ENFORCEMENT'),
                hash_including('code' => 'GPumYGQ00F', 'type' => 'COUNTY_LICENSING')
              ),
              'inform_date' => '2018-05-11T18:10:00.000Z',
              'method' => communication_method
            )
          )
        )
      )
    ).to have_been_made
  end

  scenario 'editing cross reports to an existing screening' do
    reported_on = DateTime.strptime('5/11/2018 11:10 AM', '%m/%d/%Y %l:%M %p')
    communication_method = 'Child Abuse Form'

    existing_screening[:cross_reports] = [{
      county_id: 'c42',
      agencies: [
        { code: 'GPumYGQ00F', type: 'COUNTY_LICENSING' },
        { code: 'BMG2f3J75C', type: 'LAW_ENFORCEMENT' }
      ],
      method: communication_method,
      inform_date: reported_on.strftime('%m/%d/%Y %l:%M %p')
    }]
    stub_request(
      :get, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_request(
      :put, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)
    visit edit_screening_path(id: existing_screening[:id])

    expect(page).to have_select('County', selected: 'Sacramento')
    select 'San Francisco', from: 'County'
    expect(page).to have_select('County', selected: 'San Francisco')

    expect(find(:checkbox, 'County Licensing')).to_not be_checked

    click_link('Cross Report')

    find('label', text: /\ALaw Enforcement\z/).click
    expect(find(:checkbox, 'Law Enforcement')).to be_checked

    select 'The Sheriff', from: 'Law Enforcement Agency Name'
    find('label', text: /\ADistrict Attorney\z/).click
    page.execute_script 'window.scrollBy(0,100)'
    fill_in_datepicker 'Cross Reported on Date', with: reported_on.strftime('%m/%d/%Y %l:%M %p')
    expect(find_field('Cross Reported on Date').value).to \
      eq(reported_on.strftime('%m/%d/%Y %l:%M %p'))
    within '#cross-report-card' do
      select communication_method, from: 'Communication Method'
    end
    click_link 'Cross Report'
    page.execute_script 'window.scrollBy(0,500)'
    page.find(:xpath, '//*[@id="cross-report-card"]/div[2]/div[5]/div/div/button[2]').click
    expect(
      a_request(
        :put, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
      ).with(
        body: hash_including(
          'cross_reports' => array_including(
            hash_including(
              'county_id' => 'c40',
              'agencies' => array_including(
                hash_including('code' => 'BMG2f3J75C', 'type' => 'LAW_ENFORCEMENT'),
                hash_including('code' => '45Hvp7x00F', 'type' => 'DISTRICT_ATTORNEY')
              ),
              'inform_date' => '2018-05-11T18:10:00.000Z',
              'method' => communication_method
            )
          )
        )
      )
    ).to have_been_made
  end

  scenario 'viewing cross reports on an existing screening' do
    reported_in_utc = DateTime.strptime('5/11/2018 04:10 AM', '%m/%d/%Y %l:%M %p')
    reported_on = reported_in_utc.in_time_zone('Pacific Time (US & Canada)')

    existing_screening[:cross_reports] = [{
      county_id: 'c42',
      agencies: [
        { code: 'LsUFj7O00E', type: 'COMMUNITY_CARE_LICENSING' },
        { code: 'BMG2f3J75C', type: 'LAW_ENFORCEMENT' }
      ],
      method: 'Child Abuse Form',
      inform_date: reported_in_utc.utc.iso8601
    }]
    stub_request(
      :get, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)
    visit screening_path(id: existing_screening[:id])

    within '#cross-report-card', text: 'Cross Report' do
      expect(page).to_not have_content 'County'
      expect(page).to_not have_content 'Sacramento'
      expect(page).to have_content 'Community Care Licensing'
      expect(page).to have_content "Daisie's Preschool"
      expect(page).to have_content 'Law Enforcement'
      expect(page).to have_content 'The Sheriff'
      expect(page).to have_content reported_on.strftime('%m/%d/%Y %l:%M %p')
      expect(page).to have_content 'Child Abuse Form'
    end

    click_link 'Edit cross report'

    within '#cross-report-card', text: 'Cross Report' do
      expect(page).to have_select('County', selected: 'Sacramento')
      expect(find(:checkbox, 'Law Enforcement')).to be_checked
      expect(page).to have_select('Law Enforcement Agency Name', selected: 'The Sheriff')
      expect(find(:checkbox, 'Community Care Licensing')).to be_checked
      expect(page).to have_select('Community Care Licensing Agency Name',
        selected: "Daisie's Preschool")
      expect(page).to have_field('Communication Method', with: 'Child Abuse Form')
      expect(page).to \
        have_field('Cross Reported on Date', with: reported_on.strftime('%m/%d/%Y %-l:%M %p'))
    end
  end

  scenario 'viewing empty cross reports on an existing screening' do
    stub_request(
      :get,
      ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)
    visit screening_path(id: existing_screening[:id])

    within '#cross-report-card', text: 'Cross Report' do
      expect(page).to_not have_content 'County'
      expect(page).to_not have_content 'Communication Time and Method'
      expect(page).to_not have_content 'Cross Reported on Date'
      expect(page).to_not have_content 'Communication Method'
    end
  end

  scenario 'communication method and time fields are cached' do
    stub_request(
      :get, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_request(
      :put, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)
    visit edit_screening_path(id: existing_screening[:id])

    reported_on = DateTime.strptime('5/11/2018 11:10 AM', '%m/%d/%Y %l:%M %p')
    communication_method = 'Child Abuse Form'

    select 'State of California', from: 'County'
    click_link('Cross Report')
    find('label', text: /\ACounty Licensing\z/).click
    fill_in_datepicker 'Cross Reported on Date', with: reported_on.strftime('%m/%d/%Y %l:%M %p')
    within '#cross-report-card' do
      select communication_method, from: 'Communication Method'
    end
    click_link('Cross Report')
    find('label', text: /\ACounty Licensing\z/).click
    find('label', text: /\ALaw Enforcement\z/).click
    expect(page).to \
      have_field('Cross Reported on Date', with: reported_on.strftime('%m/%d/%Y %l:%M %p'))
    expect(page).to have_field('Communication Method', with: communication_method)
    click_link 'Cross Report'
    page.execute_script 'window.scrollBy(0,500)'
    page.find(:xpath, '//*[@id="cross-report-card"]/div[2]/div[5]/div/div/button[2]').click

    expect(
      a_request(
        :put, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
      ).with(
        body: hash_including(
          'cross_reports' => array_including(
            hash_including(
              'agencies' => array_including(
                hash_including('code' => 'BMG2f3J75C', 'type' => 'LAW_ENFORCEMENT')
              ),
              'inform_date' => '2018-05-11T18:10:00.000Z',
              'method' => communication_method
            )
          )
        )
      )
    ).to have_been_made
  end

  scenario 'communication method and time fields are cleared after county change' do
    stub_request(
      :get, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_request(
      :put, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)
    visit edit_screening_path(id: existing_screening[:id])

    reported_on = DateTime.strptime('5/11/2018 11:10 AM', '%m/%d/%Y %l:%M %p')
    communication_method = 'Child Abuse Form'

    select 'San Francisco', from: 'County'
    click_link('Cross Report')
    find('label', text: /\ACounty Licensing\z/).click
    fill_in_datepicker 'Cross Reported on Date', with: reported_on.strftime('%m/%d/%Y %l:%M %p')
    within '#cross-report-card' do
      select communication_method, from: 'Communication Method'
    end
    click_link('Cross Report')
    find('label', text: /\ACounty Licensing\z/).click
    find('label', text: /\ALaw Enforcement\z/).click
    expect(page).to \
      have_field('Cross Reported on Date', with: reported_on.strftime('%m/%d/%Y %l:%M %p'))
    expect(page).to have_field('Communication Method', with: communication_method)
    select 'State of California', from: 'County'
    click_link('Cross Report')
    find('label', text: /\ALaw Enforcement\z/).click
    expect(page).to_not \
      have_field('Cross Reported on Date', with: reported_on.strftime('%m/%d/%Y %l:%M %p'))
    expect(page).to_not have_field('Communication Method', with: communication_method)
    click_link 'Cross Report'
    page.execute_script 'window.scrollBy(0,500)'
    page.find(:xpath, '//*[@id="cross-report-card"]/div[2]/div[5]/div/div/button[2]').click

    expect(
      a_request(
        :put, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
      ).with(
        body: hash_including(
          'cross_reports' => array_including(
            hash_including(
              'agencies' => array_including(
                hash_including('code' => 'BMG2f3J75C', 'type' => 'LAW_ENFORCEMENT')
              ),
              'inform_date' => nil,
              'method' => nil
            )
          )
        )
      )
    ).to have_been_made
  end

  scenario 'communication method and time fields are cleared from cache after save' do
    stub_request(
      :get, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_request(
      :put, ferb_api_url(FerbRoutes.intake_screening_path(existing_screening[:id]))
    ).and_return(json_body(existing_screening.to_json, status: 200))
    stub_empty_relationships
    stub_empty_history_for_screening(existing_screening)
    visit edit_screening_path(id: existing_screening[:id])

    reported_on = Date.today
    communication_method = 'Child Abuse Form'

    select 'State of California', from: 'County'
    click_link('Cross Report')
    find('label', text: /\ACounty Licensing\z/).click
    fill_in_datepicker 'Cross Reported on Date', with: reported_on
    within '#cross-report-card' do
      select communication_method, from: 'Communication Method'
    end
    click_link 'Cross Report'
    page.execute_script 'window.scrollBy(0,500)'
    page.find(:xpath, '//*[@id="cross-report-card"]/div[2]/div[5]/div/div/button[2]').click
    click_link 'Cross Report'
    click_link 'Edit cross report'

    select 'Sacramento', from: 'County'
    click_link 'Cross Report'
    find('label', text: /\ACounty Licensing\z/).click
    expect(page).to have_field('Cross Reported on Date', with: '')
    expect(page).to have_field('Communication Method', with: '')
  end
end
