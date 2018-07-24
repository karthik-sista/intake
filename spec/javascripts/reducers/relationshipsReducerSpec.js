import * as matchers from 'jasmine-immutable-matchers'
import relationshipsReducer from 'reducers/relationshipsReducer'
import {
  createScreeningSuccess,
  createScreeningFailure,
} from 'actions/screeningActions'
import {
  clearRelationships,
  fetchRelationshipsSuccess,
  fetchRelationshipsFailure,
  setField,
} from 'actions/relationshipsActions'
import {List, fromJS} from 'immutable'

describe('relationshipsReducer', () => {
  beforeEach(() => jasmine.addMatchers(matchers))

  describe('on FETCH_RELATIONSHIPS_COMPLETE', () => {
    it('returns the relationships from the action on success', () => {
      const relationships = fromJS([
        {id: 1, legacy_id: 'ABC', relationships: []},
        {id: 2, legacy_id: 'DEF', relationsihps: []},
      ])
      const action = fetchRelationshipsSuccess(relationships.toJS())
      expect(relationshipsReducer(List(), action)).toEqualImmutable(relationships)
    })
    it('returns the last state on failure', () => {
      const oldState = fromJS([{id: 1, legacy_id: 'ABC'}])
      const action = fetchRelationshipsFailure()
      expect(relationshipsReducer(oldState, action))
        .toEqual(oldState)
    })
    it('sets legacy_id from descriptor', () => {
      const relationships = [
        {id: 1, legacy_id: 'ABC'},
        {id: 2, legacy_descriptor: {legacy_id: 'DEF'}},
      ]
      const action = fetchRelationshipsSuccess(relationships)
      expect(relationshipsReducer(List(), action)).toEqualImmutable(fromJS([
        {id: 1, legacy_id: 'ABC'},
        {id: 2, legacy_id: 'DEF', legacy_descriptor: {legacy_id: 'DEF'}},
      ]))
    })

    // We need to support this for a little while due to a typo in Ferb
    it('sets legacy_id from "descirptor"', () => {
      const relationships = [
        {id: 1, legacy_id: 'ABC'},
        {id: 2, legacy_descirptor: {legacy_id: 'DEF'}},
      ]
      const action = fetchRelationshipsSuccess(relationships)
      expect(relationshipsReducer(List(), action)).toEqualImmutable(fromJS([
        {id: 1, legacy_id: 'ABC'},
        {id: 2, legacy_id: 'DEF', legacy_descriptor: {legacy_id: 'DEF'}},
      ]))
    })

    it('sets relationships from relationship_to', () => {
      const relationships = [
        {id: 1, relationship_to: ['ABC']},
      ]
      const action = fetchRelationshipsSuccess(relationships)
      expect(relationshipsReducer(List(), action)).toEqualImmutable(fromJS([
        {id: 1, relationships: ['ABC']},
      ]))
    })
  })

  describe('on CREATE_SCREENING_COMPLETE', () => {
    it('returns an empty immutable list on success', () => {
      const oldState = fromJS([{id: 1}])
      const action = createScreeningSuccess([])
      expect(relationshipsReducer(oldState, action).isEmpty()).toEqual(true)
    })
    it('returns the last state on failure', () => {
      const oldState = fromJS([{id: 1}])
      const action = createScreeningFailure()
      expect(relationshipsReducer(oldState, action))
        .toEqual(oldState)
    })
  })

  describe('on CLEAR_RELATIONSHIPS', () => {
    it('clears all the relationships from the relationships reducer', () => {
      const oldState = fromJS([{id: 1, legacy_id: 'ABC'}])
      const action = clearRelationships()
      expect(relationshipsReducer(oldState, action).isEmpty()).toEqual(true)
    })
  })
})
