# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

feature 'Relationship card' do
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
  let(:empty_response) do
    {
      hits: {
        total: 1,
        hits: []
      }
    }
  end
  let(:participant) { FactoryBot.create(:participant) }
  let(:participants_screening) do
    {
      id: '1',
      incident_address: {},
      addresses: [],
      cross_reports: [],
      participants: [participant.as_json.symbolize_keys],
      allegations: [],
      safety_alerts: []
    }
  end
  let(:relationships) do
    [
      {
        id: participant.id.to_s,
        first_name: participant.first_name,
        last_name: participant.last_name,
        relationships: [].push(jane, jake),
        legacy_id: 'jane_legacy_id'
      }
    ]
  end
  let(:new_participant) do
    FactoryBot.create(
      :participant,
      first_name: 'Jane',
      last_name: 'Campbell',
      screening_id: participants_screening[:id]
    )
  end
  let(:jake) do
    {
      related_person_first_name: 'Jake',
      related_person_last_name: 'Campbell',
      relationship: 'Sister/Brother (Half)',
      related_person_relationship: '18',
      indexed_person_relationship: '277',
      relationship_context: 'Half',
      related_person_id: '7'
    }
  end
  let(:jane) do
    {
      related_person_id: new_participant.id,
      related_person_legacy_id: '280',
      related_person_first_name: 'Jane',
      related_person_last_name: 'Campbell',
      relationship: 'Sister/Sister (Half)',
      related_person_relationship: '280',
      indexed_person_relationship: '280',
      relationship_context: 'Half',
      legacy_descriptor: {
        legacy_id: 'jane_legacy_id'
      }
    }
  end
  let(:new_relationships) do
    [
      {
        id: participant.id.to_s,
        first_name: participant.first_name,
        last_name: participant.last_name,
        relationships: [].push(jane, jake)
      },
      {
        id: new_participant.id.to_s,
        first_name: new_participant.first_name,
        last_name: new_participant.last_name,
        relationships: []
      }
    ]
  end
  let(:hoi) do
    {
      id: participants_screening[:id],
      cases: [],
      referrals: [],
      screenings: [
        {
          id: '1',
          start_date: '2018-02-26',
          assigned_social_worker: {
            id: '0X5',
            first_name: 'Testing',
            last_name: 'CWDS',
            legacy_descriptor: {
              legacy_id: '0X5'
            }
          },
          all_people: [
            {
              id: new_participant.id,
              first_name: new_participant.first_name,
              last_name: new_participant.last_name,
              legacy_descriptor: {
                legacy_id: 'jane_legacy_id'
              }
            }
          ]
        }
      ]
    }
  end

  before do
    stub_system_codes
  end

  context 'a screening without participants' do
    scenario 'edit an existing screening' do
      stub_and_visit_edit_screening(existing_screening)

      should_have_content('Search for people and add them to see their relationships.',
        inside: '#relationships-card')
    end

    scenario 'view an existing screening' do
      stub_and_visit_show_screening(existing_screening)

      should_have_content('Search for people and add them to see their relationships.',
        inside: '#relationships-card')
    end
  end

  context 'a screening with participants' do
    before do
      stub_request(:get,
        ferb_api_url(
          FerbRoutes.intake_screening_path(participants_screening[:id])
        )).and_return(json_body(participants_screening.to_json))
      stub_empty_history_for_screening(participants_screening)

      stub_request(
        :get,
        ferb_api_url(FerbRoutes.relationships_path)
      ).with(query: hash_including({})).and_return(json_body(relationships.to_json, status: 200))
    end

    scenario 'viewing a screening' do
      visit screening_path(id: participants_screening[:id])

      within '#relationships-card.card.show', text: 'Relationships' do
        expect(page).to have_content(
          "#{relationships.first[:first_name]} #{relationships.first[:last_name]} is the.."
        )
        expect(page).to have_content('Sister (Half) of Jake Campbell')
        expect(page).to have_content('Sister (Half) of Jane Campbell')
      end

      expect(
        a_request(
          :get,
          ferb_api_url(FerbRoutes.relationships_path)
        ).with(query: { 'clientIds' => participant.legacy_descriptor.legacy_id })
      ).to have_been_made
    end

    describe 'editing a screening' do
      scenario 'loads relationships on initial page load' do
        stub_empty_history_for_screening(participants_screening)
        visit edit_screening_path(id: participants_screening[:id])

        within '#relationships-card.card.show', text: 'Relationships' do
          expect(page).to have_content(
            "#{relationships.first[:first_name]} #{relationships.first[:last_name]} is the.."
          )

          expect(page).to have_content('Sister (Half) of Jake Campbell')
          expect(page).to have_content('Sister (Half) of Jane Campbell')
        end

        expect(
          a_request(
            :get,
            ferb_api_url(FerbRoutes.relationships_path)
          ).with(query: { 'clientIds' => participant.legacy_descriptor.legacy_id })
        ).to have_been_made
      end

      scenario 'adding a new person fetches new relationships' do
        visit edit_screening_path(id: participants_screening[:id])
        screening_id = participants_screening[:id]

        stub_request(:post,
          intake_api_url(ExternalRoutes.intake_api_screening_people_path(screening_id)))
          .and_return(json_body(new_participant.to_json, status: 201))

        stub_request(
          :get,
          ferb_api_url(FerbRoutes.relationships_path)
        ).with(query: hash_including({}))
          .and_return(json_body(new_relationships.to_json, status: 200))

        stub_person_search(search_term: 'ma', person_response: empty_response)
        stub_person_search(search_term: 'undefined undefined', person_response: empty_response)

        within '#search-card', text: 'Search' do
          fill_in 'Search for any person', with: 'ma'
        end

        within '#search-card', text: 'Search' do
          click_button 'Create a new person'
        end

        within edit_participant_card_selector(new_participant.id) do
          should_have_content('Jane Campbell', inside: '.card-header')
        end

        expect(
          a_request(
            :get,
            ferb_api_url(FerbRoutes.relationships_path)
          ).with(query: { 'clientIds' => participant.legacy_descriptor.legacy_id })
        ).to have_been_made.twice

        within '#relationships-card.card.show', text: 'Relationships' do
          expect(page).to have_content(
            "#{relationships.first[:first_name]} #{relationships.first[:last_name]} is the.."
          )
          expect(page).to have_content('Sister (Half) of Jake Campbell')

          expect(page).to have_content(
            "#{new_participant.first_name} #{new_participant.last_name} has no known relationships"
          )
        end
      end

      scenario 'saving a new person fetches new relationships' do
        visit edit_screening_path(id: participants_screening[:id])

        stub_request(:put,
          intake_api_url(ExternalRoutes.intake_api_participant_path(participant.id)))
          .and_return(json_body(participant.to_json, status: 201))

        within edit_participant_card_selector(participant.id) do
          click_button 'Save'
        end

        expect(
          a_request(:put,
            intake_api_url(
              ExternalRoutes.intake_api_participant_path(participant.id)
            ))
        ).to have_been_made

        expect(
          a_request(
            :get,
            ferb_api_url(FerbRoutes.relationships_path)
          ).with(query: { 'clientIds' => participant.legacy_descriptor.legacy_id })
        ).to have_been_made.times(2)
      end

      context '#attach-relationships to screening' do
        before(:each) do
          new_relationships.last[:relationships].push(jake)
          stub_empty_history_for_screening(participants_screening, response: hoi)
          visit edit_screening_path(id: participants_screening[:id])

          stub_request(:post,
            intake_api_url(
              ExternalRoutes.intake_api_screening_people_path(participants_screening[:id])
            )).and_return(json_body(new_participant.to_json, status: 201))
        end

        describe '#relationships-card' do
          describe '.unattached-person' do
            scenario 'allows attachment' do
              assign_relationship(tag: 'li', element_text: 'Sister (Half) of Jake Campbell')
              expect(
                a_request(:post,
                  intake_api_url(
                    ExternalRoutes
                      .intake_api_screening_people_path(participants_screening[:id])
                  ))
              ).to have_been_made.times(1)
            end

            scenario 'attached person should appear on the current screening' do
              assign_relationship(tag: 'li', element_text: 'Sister (Half) of Jake Campbell')
              expect(page).to have_css("div#participants-card-#{new_participant.id}")
            end

            scenario 'show relationships for the newly attached person' do
              new_relationships.last[:relationships].push(jake)
              stub_request(
                :get,
                ferb_api_url(FerbRoutes.relationships_path)
              ).with(query: hash_including({}))
                .and_return(json_body(new_relationships.to_json, status: 200))

              assign_relationship(tag: 'li', element_text: 'Sister (Half) of Jake Campbell')

              expect(page).to have_content('Jane Campbell is the...')
              expect(page).to have_content('Sister (Half)   of Jake Campbell')
            end

            scenario 'should display the name of the newly attached person in sidebar' do
              assign_relationship(tag: 'li', element_text: 'Sister (Half) of Jake Campbell')
              should_have_content('Jane Campbell', inside: 'div.side-bar')
            end
          end

          describe '.attached-person' do
            scenario 'does not show "Attach" link' do
              find(:xpath, ".//li[contains(., 'of Jake Campbell')]//a").click
              expect(page).not_to have_xpath(".//li[contains(., 'of Jake Campbell')]//a")
            end
          end
        end

        describe '#history-of-involvement' do
          describe 'newly .attached-person to screening' do
            before(:each) do
              assign_relationship(tag: 'li', element_text: 'Sister (Half) of Jake Campbell')
            end

            scenario 'should show existing screenings' do
              text = [new_participant.first_name,
                      new_participant.last_name].join(' ')
              should_have_content(text, inside: 'div#history-card')
            end

            scenario 'does not show duplicated screenings' do
              expect(
                a_request(:get,
                  ferb_api_url(
                    FerbRoutes.screening_history_of_involvements_path(participants_screening[:id])
                  ))
              ).to have_been_made.twice

              expect(page).to \
                have_selector('td', text: [new_participant.first_name,
                                           new_participant.last_name].join(' '),
                                    count: 1)
            end
          end
        end
      end
    end
  end
end
