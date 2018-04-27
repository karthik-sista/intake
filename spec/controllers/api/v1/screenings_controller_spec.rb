# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::ScreeningsController do
  let(:security_token) { 'security_token' }
  let(:staff) { FactoryBot.build(:staff, staff_id: '123') }
  let(:session) do
    {
      'security_token' => security_token,
      'user_details' => staff
    }
  end

  describe 'permitted attributes' do
    describe '#create' do
      before do
        allow(LUID).to receive(:generate).and_return(['123ABC'])
      end
      it 'defaults indexable to true' do
        screening_params = { indexable: false }
        allow(ScreeningRepository).to receive(:create)
        process :create, method: :post, session: session, params: screening_params
      end
    end
  end

  describe '#create' do
    let(:created_screening) do
      {
        reference: "123ABC",
        assignee: "#{staff.first_name} #{staff.last_name} - #{staff.county}",
        assignee_staff_id: staff.staff_id.to_s,
        incident_county: nil,
        indexable: true,
        addresses: [],
        cross_reports: [],
        participants: [],
        allegations: []
      }
    end

    let(:blank_screening) do
      {
        reference: "123ABC",
        indexable: true,
        addresses: [],
        cross_reports: [],
        participants: [],
        allegations: []
      }
    end
    before do
      allow(LUID).to receive(:generate).and_return(['123ABC'])
      expect(ScreeningRepository).to receive(:create)
        .with(security_token, created_screening)
        .and_return(created_screening)
    end

    it 'creates and renders screening as json' do
      process :create, method: :post, session: session
      expect(response).to be_successful
      expect(JSON.parse(response.body)).to eq(created_screening.as_json)
    end

    describe 'setting assignee when user_details are not set' do
      let(:created_screening) do
        {
          reference: "123ABC",
          assignee: nil,
          assignee_staff_id: nil,
          incident_county: nil,
          indexable: true,
          addresses: [],
          cross_reports: [],
          participants: [],
          allegations: []
        }
      end

      it 'leaves assignee and assignee_staff_id as nil' do
        session = { 'security_token' => security_token }
        process :create, method: :post, session: session
        expect(response).to be_successful
      end
    end

    describe 'setting assignee when user details is empty' do
      let(:created_screening) do
        {
          reference: "123ABC",
          assignee: '',
          assignee_staff_id: nil,
          incident_county: nil,
          indexable: true,
          addresses: [],
          cross_reports: [],
          participants: [],
          allegations: []
        }
      end

      it 'is blank if user_details is empty' do
        staff = FactoryBot.build(:staff, first_name: nil, last_name: nil, county: nil)
        session = { 'security_token' => security_token, 'user_details' => staff }
        process :create, method: :post, session: session
        expect(response).to be_successful
      end
    end

    describe 'setting assignee when user_details is set' do
      let(:created_screening) do
        {
          reference: "123ABC",
          assignee: "#{staff.first_name} Q. #{staff.last_name} - #{staff.county}",
          assignee_staff_id: staff.staff_id.to_s,
          incident_county: nil,
          indexable: true,
          addresses: [],
          cross_reports: [],
          participants: [],
          allegations: []
        }
      end

      describe 'with first middle and last name set' do
        let(:staff) { FactoryBot.build(:staff, middle_initial: 'Q', staff_id: '456') }
        let(:created_screening) do
          {
            reference: "123ABC",
            assignee: "#{staff.first_name} Q. #{staff.last_name} - #{staff.county}",
            assignee_staff_id: staff.staff_id.to_s,
            incident_county: nil,
            indexable: true,
            addresses: [],
            cross_reports: [],
            participants: [],
            allegations: []
          }
        end

        it 'formats assignee as first mi. last - county if all exist' do
          session = {
            'security_token' => security_token,
            'user_details' => staff
          }
          process :create, method: :post, session: session
          expect(response).to be_successful
        end
      end

      describe 'with first last and no middle initial set' do
        let(:staff) { FactoryBot.build(:staff, staff_id: '456') }
        let(:created_screening) do
          {
            reference: "123ABC",
            assignee: "#{staff.first_name} #{staff.last_name} - #{staff.county}",
            assignee_staff_id: staff.staff_id.to_s,
            incident_county: nil,
            indexable: true,
            addresses: [],
            cross_reports: [],
            participants: [],
            allegations: []
          }
        end

        it 'formats assignee as first last - county if no middle initial' do
          session = {
            'security_token' => security_token,
            'user_details' => staff
          }
          process :create, method: :post, session: session
          expect(response).to be_successful
        end

        it 'returns the same name if run more than once' do
          # Added second expectation as in the before so both create calls are properly expected
          expect(ScreeningRepository).to receive(:create)
            .with(security_token, created_screening)
            .and_return(created_screening)
          session = {
            'security_token' => security_token,
            'user_details' => staff
          }
          process :create, method: :post, session: session
          process :create, method: :post, session: session
        end
      end
    end

    describe 'setting incident county' do
      describe 'user details not set' do
        let(:created_screening) do
          {
            reference: "123ABC",
            assignee: nil,
            assignee_staff_id: nil,
            incident_county: nil,
            indexable: true,
            addresses: [],
            cross_reports: [],
            participants: [],
            allegations: []
          }
        end
        let(:session) do
          { 'security_token' => security_token }
        end

        it 'leaves incident county as nil if user_details is not set' do
          process :create, method: :post, session: session
          expect(response).to be_successful
        end
      end

      describe 'user details is empty' do
        let(:staff) do
          FactoryBot.build(
            :staff,
            first_name: nil,
            last_name: nil,
            county: nil,
            county_code: nil
          )
        end
        let(:created_screening) do
          {
            reference: "123ABC",
            assignee: "",
            assignee_staff_id: nil,
            incident_county: nil,
            indexable: true,
            addresses: [],
            cross_reports: [],
            participants: [],
            allegations: []
          }
        end
        it 'is blank if user_details is empty' do
          process :create, method: :post, session: session
          expect(response).to be_successful
        end
      end

      describe 'user details has info county' do
        let(:staff) do
          FactoryBot.build(:staff, county: 'yolo', staff_id: '456', county_code: '123')
        end
        let(:created_screening) do
          {
            reference: "123ABC",
            assignee: "#{staff.first_name} #{staff.last_name} - #{staff.county}",
            assignee_staff_id: '456',
            incident_county: '123',
            indexable: true,
            addresses: [],
            cross_reports: [],
            participants: [],
            allegations: []
          }
        end

        it 'default to have user info county' do
          process :create, method: :post, session: session
          expect(response).to be_successful
        end
      end
    end
  end

  describe '#show' do
    let(:screening) { double(:screening) }

    before do
      expect(ScreeningRepository).to receive(:find)
        .with(security_token, '1')
        .and_return(screening)
    end

    it 'renders screening as json' do
      process :show, method: :get, params: { id: '1' }, session: session
      expect(JSON.parse(response.body)).to eq(screening.as_json)
    end
  end

  describe '#update' do
    let(:screening_params) do
      {
        id: '1',
        assignee: 'Robert Smith',
        additional_information: 'the new decision is updated',
        incident_county: '1234',
        name: '123 Report',
        screening_decision: 'evaluate_out',
        access_restrictions: 'sensitive',
        restrictions_rationale: 'Someone in this screening has sensitive information',
        cross_reports: [
          {
            inform_date: '1990-01-15',
            method: 'Child Abuse Form',
            county_id: '1234',
            agencies: [
              { type: 'DEPARTMENT_OF_JUSTICE', id: 'SCDOFFCODE' },
              { type: 'COUNTY_LICENSING', id: 'SCDLICCODE' }
            ]
          }
        ],
        address: {
          id: '2',
          city: 'LA',
          state: 'CA',
          street_address: '123 Fake St',
          zip: '11222'
        },
        allegations: [{
          id: '2',
          screening_id: '3',
          perpetrator_id: '4',
          perpetrator: { first_name: 'name' },
          victim_id: '5',
          victim: { first_name: 'name' },
          allegation_types: ['General neglect']
        }]
      }.with_indifferent_access
    end
    let(:unallowed_params) { %i[perpetrator victim] }
    let(:updated_screening) { double(:screening, as_json: { 'id' => 'updated_screening' }) }

    before do
      screening = double(:screening)
      screening_attributes = screening_params.as_json(except: unallowed_params)
      expect(Screening).to receive(:new).with(screening_attributes).and_return(screening)
      expect(ScreeningRepository).to receive(:update)
        .with(security_token, screening)
        .and_return(updated_screening)
    end

    it 'updates and renders screening as json' do
      process :update,
        method: :put,
        params: { id: screening_params[:id], screening: screening_params },
        format: :json,
        session: session
      expect(response).to be_successful
      expect(JSON.parse(response.body)).to eq(updated_screening.as_json)
    end
  end

  describe '#index' do
    context 'without screening_decisions' do
      let(:screenings) { double(:screenings, as_json: [{ id: '1' }]) }
      before do
        allow(ScreeningRepository).to receive(:search)
          .with(security_token)
          .and_return(screenings)
      end

      it 'renders screenings as json' do
        process :index, method: :get, session: session
        expect(JSON.parse(response.body)).to eq([{ 'id' => '1' }])
      end
    end
  end

  describe '#history_of_involvements' do
    let(:involvements) { [{ 'id' => 1 }, { 'id' => 2 }] }
    let(:screening_id) { '99' }

    before do
      expect(ScreeningRepository).to receive(:history_of_involvements)
        .with(security_token, screening_id)
        .and_return(involvements)
    end

    it 'returns history of involvements' do
      get :history_of_involvements, params: { id: screening_id }, session: session
      expect(response).to be_successful
      expect(response.body).to eq involvements.to_json
    end
  end

  describe '#submit' do
    let(:screening_id) { '99' }
    let(:submit_response) do
      { referral_id: FFaker::Guid.guid }
    end

    before do
      expect(ScreeningRepository).to receive(:submit)
        .with(security_token, screening_id)
        .and_return(submit_response)
    end

    it 'submits screening' do
      post :submit, params: { id: screening_id }, session: session
      expect(response).to be_successful
      expect(response.body).to eq submit_response.to_json
    end
  end
end
