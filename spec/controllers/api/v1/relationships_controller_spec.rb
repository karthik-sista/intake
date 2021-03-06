# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::RelationshipsController do
  let(:security_token) { 'my_security_token' }
  let(:session) { { security_token: security_token } }

  let(:expected_json) do
    [
      {
        id: '12',
        first_name: 'Aubrey',
        last_name: 'Campbell',
        relationships: [
          {
            first_name: 'Jake',
            last_name: 'Campbell',
            relationship: 'Sister',
            related_person_id: '7'
          }
        ]
      }
    ].to_json
  end

  describe '#index' do
    let(:client_ids) do
      ['12']
    end

    before do
      expect(RelationshipsRepository).to receive(:search)
        .with(security_token, client_ids)
        .and_return(expected_json)
    end

    it 'responds with success' do
      process :index,
        method: :get,
        params: { clientIds: client_ids.join(',') },
        session: session
      expect(JSON.parse(response.body)).to match array_including(
        a_hash_including(
          'id' => '12',
          'first_name' => 'Aubrey',
          'last_name' => 'Campbell',
          'relationships' => array_including(
            a_hash_including(
              'first_name' => 'Jake',
              'last_name' => 'Campbell',
              'relationship' => 'Sister',
              'related_person_id' => '7'
            )
          )
        )
      )
    end
  end
end
