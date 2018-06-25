# frozen_string_literal: true

require 'rails_helper'

describe FerbRoutes do
  describe '.staff_path' do
    it 'returns /staffpersons/:id' do
      expect(described_class.staff_path(24)).to eq('/staffpersons/24')
    end
  end

  describe '.screening_history_of_involvements_path' do
    it 'returns /screenings/:id/history_of_involvements' do
      expect(described_class.screening_history_of_involvements_path(82)).to eq(
        '/screenings/82/history_of_involvements'
      )
    end
  end

  describe '.screening_participant_path' do
    it 'returns /screenings/:id/participant' do
      expect(described_class.screening_participant_path(97)).to eq(
        '/screenings/97/participant'
      )
    end
  end

  describe '.screening_submit_path' do
    it 'returns /screenings/:id/submit' do
      expect(described_class.screening_submit_path(32)).to eq(
        '/screenings/32/submit'
      )
    end
  end

  describe '.relationships_path' do
    it 'returns the base path' do
      expect(described_class.relationships_path).to eq(
        '/clients/relationships'
      )
    end
  end

  describe '.history_of_involvements_path' do
    it 'returns the base path' do
      expect(described_class.history_of_involvements_path).to eq(
        '/clients/history_of_involvements'
      )
    end
  end

  describe '.save_relationship_path' do
    it 'returns the base path' do
      expect(described_class.save_relationship_path).to eq(
        '/screening_relationships'
      )
    end
  end

  describe '.lov_path' do
    it 'returns /lov' do
      expect(described_class.lov_path).to eq('/lov')
    end
  end
end
