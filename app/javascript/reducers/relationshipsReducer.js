import {
  CREATE_SCREENING_COMPLETE,
  FETCH_RELATIONSHIPS_COMPLETE,
  CLEAR_RELATIONSHIPS,
} from 'actions/actionTypes'
import {createReducer} from 'utils/createReducer'
import {List, fromJS} from 'immutable'

const normalizeLegacyId = (relationship) =>
  relationship.update('legacy_id', (legacy_id) => (legacy_id || relationship.getIn([
    'legacy_descriptor',
    'legacy_id',
  ])))

const normalizeKeys = (relationship) =>
  relationship.mapKeys((key) => {
    if (key === 'legacy_descirptor') {
      return 'legacy_descriptor'
    }
    if (key === 'relationship_to') {
      return 'relationships'
    }
    return key
  })

export default createReducer(List(), {
  [CREATE_SCREENING_COMPLETE](state, {error}) {
    if (error) {
      return state
    } else {
      return List()
    }
  },
  [FETCH_RELATIONSHIPS_COMPLETE](state, {payload: {relationships}, error}) {
    if (error) {
      return state
    }
    return fromJS(relationships).map(normalizeKeys).map(normalizeLegacyId)
  },
  [CLEAR_RELATIONSHIPS]() {
    return List()
  },
})
