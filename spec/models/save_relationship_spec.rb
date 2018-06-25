# frozen_string_literal: true

require 'rails_helper'

describe SaveRelationship do
  describe 'as_json' do
    it 'returns the attributes as a hash' do
      attributes = {
        id: '12345',
        client_id: 'ZXY123',
        relative_id: 'ABC987',
        relationship_type: '190',
        absent_parent_indicator: false,
        same_home_status: false
      }.with_indifferent_access
      expect(described_class.new(attributes).as_json).to eq({
        id: '12345',
        client_id: 'ZXY123',
        relative_id: 'ABC987',
        relationship_type: '190',
        absent_parent_indicator: false,
        same_home_status: false
      }.with_indifferent_access)
    end
  end
end
