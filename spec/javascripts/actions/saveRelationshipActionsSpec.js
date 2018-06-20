import {
  saveRelationship,
} from 'actions/saveRelationshipActions'
import {isFSA} from 'flux-standard-action'

describe('saveRelationshipActions', () => {
  it('saveRelationship is a FSA compliant', () => {
    const action = saveRelationship({
      screening_relationships: {
        id: '12345',
        client_id: 'ZXY123',
        relative_id: 'ABC987',
        relationship_type: 190,
        absent_parent_indicator: false,
        same_home_status: false,
      },
    })
    expect(isFSA(action)).toEqual(true)
  })
})
