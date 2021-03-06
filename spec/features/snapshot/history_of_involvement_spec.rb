# frozen_string_literal: true

require 'rails_helper'
require 'feature/testing'

feature 'Snapshot History of Involvement' do
  let(:person) { FactoryBot.create(:participant, first_name: 'Marge') }

  let(:screenings) do
    [
      {
        id: '1234',
        start_date: '2016-09-10',
        county_name: 'el_dorado',
        assigned_social_worker: { first_name: nil, last_name: 'Bob Smith' },
        reporter: { first_name: 'Alex', last_name: 'Hanson' },
        all_people: [
          { first_name: nil, last_name: 'Bob Smith', roles: ['Assigned Social Worker'] },
          { first_name: 'Alex', last_name: 'Hanson', roles: ['Reporter'] },
          { first_name: 'Sally', last_name: 'Johnson', roles: ['Victim'] },
          { first_name: 'Sam', last_name: 'Anderson', roles: ['Perpetrator'] },
          { first_name: 'James', last_name: 'Robinson', roles: [] }
        ]
      },
      {
        start_date: '2016-08-10',
        end_date: '2016-11-12',
        county_name: 'el_dorado',
        reporter: { first_name: nil, last_name: nil },
        assigned_social_worker: { first_name: nil, last_name: nil },
        all_people: []
      }
    ]
  end

  let(:referrals) do
    [
      {
        id: '1234',
        start_date: '2016-11-14',
        end_date: '2016-12-14',
        county_name: 'Madera',
        response_time: 'Immediate',
        reporter: {
          first_name: 'Reporter1',
          last_name: 'r1LastName'
        },
        assigned_social_worker: {
          first_name: 'Social1',
          last_name: 's1LastName'
        },
        allegations: [{
          allegation_description: 'General Neglect',
          disposition_description: 'Entered in Error',
          perpetrator_first_name: 'Perpetrator1',
          perpetrator_last_name: 'p1LastName',
          victim_first_name: 'Victim1',
          victim_last_name: 'v1LastName'
        }],
        legacy_descriptor: {
          legacy_ui_id: '0853-2115-5670-6000802'
        },
        access_limitation: { limited_access_code: 'R' }
      },
      {
        start_date: '2016-05-06',
        county_name: 'San Francisco',
        reporter: {
          first_name: 'Reporter2',
          last_name: 'r2LastName'
        },
        assigned_social_worker: {
          first_name: 'Social2',
          last_name: 's2LastName'
        },
        allegations: [{
          allegation_description: 'Severe Neglect',
          perpetrator_first_name: 'Perpetrator2',
          perpetrator_last_name: 'p2LastName',
          victim_first_name: 'Victim2',
          victim_last_name: 'v2LastName'
        }],
        legacy_descriptor: {
          legacy_ui_id: '0202-9769-1248-2000283'
        },
        access_limitation: { limited_access_code: 'S' }
      }
    ]
  end

  let(:cases) do
    [
      {
        start_date: '2016-01-01',
        end_date: '2016-11-01',
        focus_child: {
          last_name: 'fc1Last',
          id: '0rumtwQ0Bn',
          first_name: 'fChild1'
        },
        county_name: 'El Dorado',
        service_component: 'Family Reunification',
        parents: [
          { first_name: 'Parent1', last_name: 'p1Last', id: 'AbiQA5q0Bo' },
          { first_name: 'Parent2', last_name: 'p2Last', id: 'CaTvuzq0Bo' }
        ],
        assigned_social_worker: {
          last_name: 'sw1LastName',
          first_name: 'SocialWorker1'
        },
        legacy_descriptor: {
          legacy_ui_id: '0393-5909-1798-6027230'
        },
        access_limitation: { limited_access_code: 'R' }
      },
      {
        start_date: '2016-02-03',
        focus_child: {
          last_name: 'fc2Last',
          id: '1234567',
          first_name: 'fChild2'
        },
        county_name: 'Plumas',
        parents: [
          { first_name: 'Parent3', last_name: 'p3Last', id: 'ABC123' },
          { first_name: 'Parent4', last_name: 'p4Last', id: 'ABCDEFG' }
        ],
        assigned_social_worker: {
          last_name: 'sw2LastName',
          first_name: 'SocialWorker2'
        },
        legacy_descriptor: {
          legacy_ui_id: '0208-9997-9274-0000863'
        },
        access_limitation: { limited_access_code: 'N' }
      }
    ]
  end

  let(:history) do
    {
      referrals: referrals,
      screenings: screenings,
      cases: cases
    }
  end

  before do
    stub_system_codes
  end

  context 'with no history of involvements' do
    around do |example|
      Feature.run_with_activated(:release_two) do
        example.run
      end
    end

    scenario 'snapshot displays the no HOI copy' do
      visit snapshot_path

      within '#history-card.card.show' do
        expect(page).to have_content('Search for people and add them to see their')
      end
    end
  end

  context 'a snapshot with HOI from FERB' do
    around do |example|
      Feature.run_with_activated(:release_two) do
        example.run
      end
    end

    before do
      visit snapshot_path

      stub_request(
        :get,
        ferb_api_url(
          FerbRoutes.relationships_path
        ) + "?clientIds=#{person.legacy_descriptor.legacy_id}"
      ).and_return(json_body([].to_json, status: 200))

      search_response = PersonSearchResponseBuilder.build do |response|
        response.with_total(1)
        response.with_hits do
          [
            PersonSearchResultBuilder.build do |builder|
              builder.with_first_name('Marge')
              builder.with_legacy_descriptor(person.legacy_descriptor)
            end
          ]
        end
      end
      stub_request(
        :get,
        ferb_api_url(
          FerbRoutes.history_of_involvements_path
        ) + "?clientIds=#{person.legacy_descriptor.legacy_id}"
      ).and_return(json_body(history.to_json, status: 200))

      stub_person_search(search_term: 'Ma', person_response: search_response)
      stub_request(
        :get,
        ferb_api_url(FerbRoutes.client_authorization_path(person.legacy_descriptor.legacy_id))
      ).and_return(json_body('', status: 200))
      stub_person_find(id: person.legacy_descriptor.legacy_id, person_response: search_response)

      within '#search-card', text: 'Search' do
        fill_in 'Search for clients', with: 'Ma'
      end

      within '#search-card', text: 'Search' do
        page.find('strong', text: 'Marge').click
      end
    end

    scenario 'clicking the Start Over button clears history table' do
      second_snapshot = FactoryBot.create(:screening)
      stub_request(:post, ferb_api_url(FerbRoutes.intake_screenings_path))
        .and_return(json_body(second_snapshot.to_json, status: 201))
      within '#history-card.card.show' do
        expect(page).to have_content('Referral')
      end

      click_button 'Start Over'

      within '#history-card.card.show' do
        expect(page).to have_content('Search for people and add them to see their')
      end
    end

    scenario 'copying with the copy button copies the table without reporter information' do
      within '#history-card.card.show' do
        click_button 'Copy'
      end
      #
      # Capybara has no way of checking the clipboard contents, so we insert a textarea
      # to this card to paste into and check the value.
      #
      js = [
        'var spec_meta = document.createElement("textarea")',
        'var label = document.createElement("label")',
        'label.setAttribute("for", "spec_meta")',
        'spec_meta.setAttribute("id", "spec_meta")',
        'document.getElementById("history-card").appendChild(spec_meta)',
        'document.getElementById("spec_meta").appendChild(label)',
        'document.getElementById("spec_meta").addEventListener("paste",'\
        'function(e) { e.target.value = e.clipboardData.getData("text/html") })'
      ].join(';')
      page.execute_script js
      find('#spec_meta').send_keys [:control, 'v']
      expect(find('#spec_meta').value).not_to be_empty
      expect(find('#spec_meta').value).not_to have_text('Reporter1')
      expect(find('#spec_meta').value).not_to have_text('r1LastName')
      expect(find('#spec_meta').value).not_to have_text('Reporter2')
      expect(find('#spec_meta').value).not_to have_text('r2LastName')
    end

    scenario 'viewing a snapshot displays HOI without screenings' do
      expect(
        a_request(
          :get,
          ferb_api_url(
            FerbRoutes.history_of_involvements_path
          ) + "?clientIds=#{person.legacy_descriptor.legacy_id}"
        )
      ).to have_been_made

      within '#history-card.card.show' do
        within first('tbody') do
          expect(page).to have_no_content('Screening (In Progress)')
          expect(page).to have_no_content('Screening (Closed)')

          referrals = page.all('tr', text: 'Referral')
          expect(referrals.length).to eq 2

          within referrals.first do
            expect(page).to have_content('11/14/2016 - 12/14/2016')
            expect(page).to have_content('Referral')
            expect(page).to have_content('0853-2115-5670-6000802')
            expect(page).to have_content('(Closed - Immediate)')
            expect(page).to have_content('Madera')
            expect(page).to have_content('Sealed')

            within 'table' do
              allegation_rows = page.all('tr')

              within allegation_rows[0] do
                expect(page).to have_content('Victim')
                expect(page).to have_content('Perpetrator')
                expect(page).to have_content('Allegation(s) & Conclusion(s)')
              end

              within allegation_rows[1] do
                expect(page).to have_content('Victim1 v1LastName')
                expect(page).to have_content('Perpetrator1 p1LastName')
                expect(page).to have_content('General Neglect (Entered in Error)')
              end
            end

            expect(page).to have_content('Reporter: Reporter1 r1LastName')
            expect(page).to have_content('Worker: Social1 s1LastName')
          end

          within referrals.last do
            expect(page).to have_content('05/06/2016')
            expect(page).to have_content('Referral')
            expect(page).to have_content('0202-9769-1248-2000283')
            expect(page).to have_content('(Open)')
            expect(page).to have_content('San Francisco')
            expect(page).to have_content('Sensitive')

            within 'table' do
              allegation_rows = page.all('tr')

              within allegation_rows[0] do
                expect(page).to have_content('Victim')
                expect(page).to have_content('Perpetrator')
                expect(page).to have_content('Allegation(s) & Conclusion(s)')
              end

              within allegation_rows[1] do
                expect(page).to have_content('Victim2 v2LastName')
                expect(page).to have_content('Perpetrator2 p2LastName')
                expect(page).to have_content('Severe Neglect')
                expect(page).to have_no_content('()')
              end
            end

            expect(page).to have_content('Reporter: Reporter2 r2LastName')
            expect(page).to have_content('Worker: Social2 s2LastName')
          end

          cases = page.all('tr', text: 'Case')
          expect(cases.length).to eq 2

          within cases.first do
            expect(page).to have_content('01/01/2016 - 11/01/2016')
            expect(page).to have_content('Case')
            expect(page).to have_content('0393-5909-1798-6027230')
            expect(page).to have_content('(Closed - Family Reunification)')
            expect(page).to have_content('El Dorado')
            expect(page).to have_content('Focus Child: fChild1 fc1Last')
            expect(page).to have_content('Parent(s): Parent1 p1Last, Parent2 p2Last')
            expect(page).to have_content('Worker: SocialWorker1 sw1LastName')
            expect(page).to have_content('Sealed')
          end

          within cases.last do
            expect(page).to have_content('02/03/2016')
            expect(page).to have_no_content('2016 -')
            expect(page).to have_content('Case')
            expect(page).to have_content('0208-9997-9274-0000863')
            expect(page).to have_content('Open')
            expect(page).to have_content('Plumas')
            expect(page).to have_content('Focus Child: fChild2 fc2Last')
            expect(page).to have_content('Parent(s): Parent3 p3Last, Parent4 p4Last')
            expect(page).to have_content('Worker: SocialWorker2 sw2LastName')
            expect(page).to_not have_content('Sealed')
            expect(page).to_not have_content('Sensitive')
          end
        end
      end
    end
  end

  context 'Snapshot HOI comes from Ferb even when feature :hoi_from_intake_api is on' do
    around do |example|
      Feature.run_with_activated(:release_two, :hoi_from_intake_api) do
        example.run
      end
    end

    before do
      visit snapshot_path

      stub_request(
        :get,
        ferb_api_url(
          FerbRoutes.relationships_path
        ) + "?clientIds=#{person.legacy_descriptor.legacy_id}"
      ).and_return(json_body([].to_json, status: 200))

      search_response = PersonSearchResponseBuilder.build do |response|
        response.with_total(1)
        response.with_hits do
          [
            PersonSearchResultBuilder.build do |builder|
              builder.with_first_name('Marge')
              builder.with_legacy_descriptor(person.legacy_descriptor)
            end
          ]
        end
      end
      stub_request(
        :get,
        ferb_api_url(
          FerbRoutes.history_of_involvements_path
        ) + "?clientIds=#{person.legacy_descriptor.legacy_id}"
      ).and_return(json_body(history.to_json, status: 200))

      stub_person_search(search_term: 'Ma', person_response: search_response)
      stub_request(
        :get,
        ferb_api_url(FerbRoutes.client_authorization_path(person.legacy_descriptor.legacy_id))
      ).and_return(json_body('', status: 200))
      stub_person_find(id: person.legacy_descriptor.legacy_id, person_response: search_response)

      within '#search-card', text: 'Search' do
        fill_in 'Search for clients', with: 'Ma'
      end

      within '#search-card', text: 'Search' do
        page.find('strong', text: 'Marge').click
      end
    end

    scenario 'viewing a snapshot displays HOI without screenings' do
      expect(
        a_request(
          :get,
          ferb_api_url(
            FerbRoutes.history_of_involvements_path
          ) + "?clientIds=#{person.legacy_descriptor.legacy_id}"
        )
      ).to have_been_made

      within '#history-card.card.show' do
        within first('tbody') do
          expect(page).to have_no_content('Screening (In Progress)')
          expect(page).to have_no_content('Screening (Closed)')

          referrals = page.all('tr', text: 'Referral')
          expect(referrals.length).to eq 2

          within referrals.first do
            expect(page).to have_content('11/14/2016 - 12/14/2016')
            expect(page).to have_content('Referral')
            expect(page).to have_content('0853-2115-5670-6000802')
            expect(page).to have_content('(Closed - Immediate)')
            expect(page).to have_content('Madera')
            expect(page).to have_content('Sealed')

            within 'table' do
              allegation_rows = page.all('tr')

              within allegation_rows[0] do
                expect(page).to have_content('Victim')
                expect(page).to have_content('Perpetrator')
                expect(page).to have_content('Allegation(s) & Conclusion(s)')
              end

              within allegation_rows[1] do
                expect(page).to have_content('Victim1 v1LastName')
                expect(page).to have_content('Perpetrator1 p1LastName')
                expect(page).to have_content('General Neglect (Entered in Error)')
              end
            end

            expect(page).to have_content('Reporter: Reporter1 r1LastName')
            expect(page).to have_content('Worker: Social1 s1LastName')
          end

          within referrals.last do
            expect(page).to have_content('05/06/2016')
            expect(page).to have_content('Referral')
            expect(page).to have_content('0202-9769-1248-2000283')
            expect(page).to have_content('(Open)')
            expect(page).to have_content('San Francisco')
            expect(page).to have_content('Sensitive')

            within 'table' do
              allegation_rows = page.all('tr')

              within allegation_rows[0] do
                expect(page).to have_content('Victim')
                expect(page).to have_content('Perpetrator')
                expect(page).to have_content('Allegation(s) & Conclusion(s)')
              end

              within allegation_rows[1] do
                expect(page).to have_content('Victim2 v2LastName')
                expect(page).to have_content('Perpetrator2 p2LastName')
                expect(page).to have_content('Severe Neglect')
                expect(page).to have_no_content('()')
              end
            end

            expect(page).to have_content('Reporter: Reporter2 r2LastName')
            expect(page).to have_content('Worker: Social2 s2LastName')
          end

          cases = page.all('tr', text: 'Case')
          expect(cases.length).to eq 2

          within cases.first do
            expect(page).to have_content('01/01/2016 - 11/01/2016')
            expect(page).to have_content('Case')
            expect(page).to have_content('0393-5909-1798-6027230')
            expect(page).to have_content('(Closed - Family Reunification)')
            expect(page).to have_content('El Dorado')
            expect(page).to have_content('Sealed')
            expect(page).to have_content('Focus Child: fChild1 fc1Last')
            expect(page).to have_content('Parent(s): Parent1 p1Last, Parent2 p2Last')
            expect(page).to have_content('Worker: SocialWorker1 sw1LastName')
          end

          within cases.last do
            expect(page).to have_content('02/03/2016')
            expect(page).to have_no_content('2016 -')
            expect(page).to have_content('Case')
            expect(page).to have_content('0208-9997-9274-0000863')
            expect(page).to have_content('Open')
            expect(page).to have_content('Plumas')
            expect(page).to_not have_content('Sealed')
            expect(page).to_not have_content('Sensitive')
            expect(page).to have_content('Focus Child: fChild2 fc2Last')
            expect(page).to have_content('Parent(s): Parent3 p3Last, Parent4 p4Last')
            expect(page).to have_content('Worker: SocialWorker2 sw2LastName')
          end
        end
      end
    end
  end
end
