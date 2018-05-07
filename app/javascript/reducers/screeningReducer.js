import {
  CLEAR_SCREENING,
  FETCH_SCREENING,
  CREATE_SCREENING_COMPLETE,
  FETCH_SCREENING_COMPLETE,
  SUBMIT_SCREENING_COMPLETE,
} from 'actions/actionTypes'
import {FETCH_SCREENING_ALLEGATIONS_COMPLETE} from 'actions/screeningAllegationsActions'
import {SAVE_SCREENING_COMPLETE} from 'actions/screeningActions'
import {createReducer} from 'utils/createReducer'
import {Map, fromJS} from 'immutable'

const getScreening = (state, {payload: {screening}, error}) => {
  if (error) {
    return state
  } else {
    return fromJS({...screening, fetch_status: 'FETCHED'})
  }
}

const buildFerbAllegations = (allegations) => (
  fromJS(
    allegations.map((allegation) => ({
      id: allegation.id.toString(),
      victim_id: allegation.victim_person_id.toString(),
      perpetrator_id: allegation.perpetrator_person_id.toString(),
      allegation_types: allegation.types,
    }))
  )
)

const getFerbScreening = (state, {payload: {screening}, error}) => {
  if (error) {
    return state
  } else {
    const {
      incident_address: {
        street_address, city, state: usState, zip,
      },
      allegations,
      ...screeningTail
    } = screening
    return fromJS({
      address: {
        street_address, city, state: usState, zip,
      },
      allegations: buildFerbAllegations(allegations).toJS(),
      ...screeningTail,
      fetch_status: 'FETCHED',
    })
  }
}

export default createReducer(Map(), {
  [FETCH_SCREENING]: (_state, _action) => Map({fetch_status: 'FETCHING'}),
  [CREATE_SCREENING_COMPLETE]: getScreening,
  [FETCH_SCREENING_COMPLETE]: getFerbScreening,
  [SAVE_SCREENING_COMPLETE]: getScreening,
  [SUBMIT_SCREENING_COMPLETE]: getScreening,
  [CLEAR_SCREENING]: () => Map(),
  [FETCH_SCREENING_ALLEGATIONS_COMPLETE]: (state, {payload: {allegations}, error}) => {
    if (error) {
      return state
    } else {
      return state.set('allegations', fromJS(allegations))
    }
  },
})
