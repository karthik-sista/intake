import * as matchers from 'jasmine-immutable-matchers'
import {
  createScreeningSuccess,
  createScreeningFailure,
  clearScreening,
  fetchScreeningSuccess,
  fetchScreeningFailure,
  submitScreeningSuccess,
  submitScreeningFailure,
  saveSuccess,
} from 'actions/screeningActions'
import {
  fetchSuccess as fetchAllegationsSuccess,
  fetchFailure as fetchAllegationsFailure,
} from 'actions/screeningAllegationsActions'
import {FETCH_SCREENING} from 'actions/actionTypes'
import screeningReducer from 'reducers/screeningReducer'
import {Map, fromJS} from 'immutable'

describe('screeningReducer', () => {
  beforeEach(() => jasmine.addMatchers(matchers))

  describe('on FETCH_SCREENING', () => {
    it('returns the screening from the action', () => {
      const action = {type: FETCH_SCREENING}
      expect(screeningReducer(Map(), action)).toEqualImmutable(
        Map({fetch_status: 'FETCHING'})
      )
    })
  })

  describe('on CREATE_SCREENING_COMPLETE', () => {
    it('returns the screening from the action on success', () => {
      const screening = {id: '1'}
      const action = createScreeningSuccess(screening)
      expect(screeningReducer(Map(), action)).toEqualImmutable(
        Map({id: '1', fetch_status: 'FETCHED'})
      )
    })

    it('does not store the participants on the screening', () => {
      const screening = {
        id: '1',
        participants: [{id: '1', first_name: 'Mario'}],
      }
      const action = createScreeningSuccess(screening)
      expect(screeningReducer(Map(), action)).toEqualImmutable(
        Map({id: '1', fetch_status: 'FETCHED'})
      )
    })

    it('returns the last state on failure', () => {
      const action = createScreeningFailure()
      expect(screeningReducer(Map(), action)).toEqualImmutable(Map())
    })
  })

  describe('on FETCH_SCREENING_COMPLETE', () => {
    it('returns the screening from the action on success', () => {
      const screening = {
        id: '1',
        incident_date: null,
        incident_county: null,
        incident_address: {},
        location_type: null,
        allegations: [],
      }
      const action = fetchScreeningSuccess(screening)
      expect(screeningReducer(Map(), action)).toEqualImmutable(
        fromJS({
          id: '1',
          incident_date: null,
          incident_county: null,
          incident_address: {},
          location_type: null,
          allegations: [],
          fetch_status: 'FETCHED',
        })
      )
    })

    it('does not store the participants on the screening', () => {
      const screening = {
        id: '1',
        incident_date: null,
        incident_county: null,
        incident_address: {},
        location_type: null,
        allegations: [],
        participants: [{id: '1', first_name: 'Mario'}],
      }
      const action = fetchScreeningSuccess(screening)
      expect(screeningReducer(Map(), action)).toEqualImmutable(
        fromJS({
          id: '1',
          incident_date: null,
          incident_county: null,
          incident_address: {},
          location_type: null,
          allegations: [],
          fetch_status: 'FETCHED',
        })
      )
    })

    it('returns the last state on failure', () => {
      const action = fetchScreeningFailure()
      expect(screeningReducer(Map(), action)).toEqualImmutable(Map())
    })
  })

  describe('on SAVE_SCREENING_COMPLETE', () => {
    it('returns the screening from the action on success', () => {
      const screening = {id: '1'}
      const action = saveSuccess(screening)
      expect(screeningReducer(Map(), action)).toEqualImmutable(
        Map({id: '1', fetch_status: 'FETCHED'})
      )
    })

    it('does not store the participants on the screening', () => {
      const screening = {
        id: '1',
        participants: [{id: '1', first_name: 'Mario'}],
      }
      const action = saveSuccess(screening)
      expect(screeningReducer(Map(), action)).toEqualImmutable(
        Map({id: '1', fetch_status: 'FETCHED'})
      )
    })
  })

  describe('on SUBMIT_SCREENING_COMPLETE', () => {
    it('returns the screening from the action on success', () => {
      const screening = {id: '1'}
      const action = submitScreeningSuccess(screening)
      expect(screeningReducer(Map(), action)).toEqualImmutable(
        Map({id: '1', fetch_status: 'FETCHED'})
      )
    })

    it('does not store the participants on the screening', () => {
      const screening = {
        id: '1',
        participants: [{id: '1', first_name: 'Mario'}],
      }
      const action = submitScreeningSuccess(screening)
      expect(screeningReducer(Map(), action)).toEqualImmutable(
        Map({id: '1', fetch_status: 'FETCHED'})
      )
    })

    it('returns the last state on failure', () => {
      const action = submitScreeningFailure()
      expect(screeningReducer(Map(), action)).toEqualImmutable(Map())
    })
  })

  describe('on FETCH_SCREENING_ALLEGATIONS_COMPLETE', () => {
    it('returns the screening with updated allegations on success', () => {
      const screening = {
        id: 1,
        screening_decision: 'promote_to_referral',
        allegations: [{
          id: 1,
          victim_person_id: 123,
          perpetrator_person_id: 456,
          types: [],
        }],
      }
      const allegations = [{
        id: 2,
        victim_person_id: 111,
        perpetrator_person_id: 222,
        types: ['General Neglect'],
      }]
      const action = fetchAllegationsSuccess(allegations)
      expect(screeningReducer(fromJS(screening), action)).toEqualImmutable(fromJS({
        id: 1,
        screening_decision: 'promote_to_referral',
        allegations: [{
          id: 2,
          victim_person_id: 111,
          perpetrator_person_id: 222,
          types: ['General Neglect'],
        }],
      }))
    })

    it('returns the last state on failure', () => {
      const action = fetchAllegationsFailure()
      expect(screeningReducer(Map(), action)).toEqualImmutable(Map())
    })
  })

  describe('on CLEAR_SCREENING', () => {
    it('clears all the screening data from the store', () => {
      const oldState = fromJS({id: 1})
      const action = clearScreening()
      expect(screeningReducer(oldState, action)).toEqual(Map())
    })
  })
})
