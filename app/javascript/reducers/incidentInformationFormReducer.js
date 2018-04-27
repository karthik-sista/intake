import {
  SET_INCIDENT_INFORMATION_FORM_FIELD,
  TOUCH_ALL_INCIDENT_INFORMATION_FORM_FIELDS,
  RESET_INCIDENT_INFORMATION_FORM_FIELDS,
  TOUCH_INCIDENT_INFORMATION_FORM_FIELD,
} from 'actions/incidentInformationFormActions'
import {FETCH_SCREENING_COMPLETE} from 'actions/actionTypes'
import {createReducer} from 'utils/createReducer'
import {untouched} from 'utils/formTouch'
import {Map, fromJS} from 'immutable'

export default createReducer(Map(), {
  [FETCH_SCREENING_COMPLETE](state, {payload: {screening}, error}) {
    if (error) { return state }

    const {
      incident_date,
      incident_county,
      incident_address: {street_address, city, state: usState, zip},
      location_type,
    } = screening

    return fromJS({
      incident_date: untouched(incident_date),
      incident_county: untouched(incident_county),
      incident_address: {
        city: untouched(city),
        state: untouched(usState),
        street_address: untouched(street_address),
        zip: untouched(zip),
      },
      location_type: untouched(location_type),
    })
  },
  [SET_INCIDENT_INFORMATION_FORM_FIELD](state, {payload: {fieldSet, value}}) {
    return state.setIn([...fieldSet, 'value'], value)
  },
  [TOUCH_ALL_INCIDENT_INFORMATION_FORM_FIELDS](state) {
    return state.setIn(['incident_date', 'touched'], true)
      .setIn(['incident_county', 'touched'], true)
      .setIn(['incident_address', 'street_address', 'touched'], true)
      .setIn(['incident_address', 'city', 'touched'], true)
      .setIn(['incident_address', 'state', 'touched'], true)
      .setIn(['incident_address', 'zip', 'touched'], true)
      .setIn(['location_type', 'touched'], true)
  },
  [TOUCH_INCIDENT_INFORMATION_FORM_FIELD](state, {payload: {field}}) {
    return state.setIn([field, 'touched'], true)
  },
  [RESET_INCIDENT_INFORMATION_FORM_FIELDS](state, {payload: {screening}}) {
    const {
      incident_date,
      incident_county,
      incident_address: {street_address, city, state: usState, zip},
      location_type,
    } = screening
    return state.setIn(['incident_date', 'value'], incident_date)
      .setIn(['incident_county', 'value'], incident_county)
      .setIn(['incident_address', 'street_address', 'value'], street_address)
      .setIn(['incident_address', 'city', 'value'], city)
      .setIn(['incident_address', 'state', 'value'], usState)
      .setIn(['incident_address', 'zip', 'value'], zip)
      .setIn(['location_type', 'value'], location_type)
  },
})
