import US_STATE from 'enums/USState'
import {createSelector} from 'reselect'
import {Map, fromJS} from 'immutable'
import {dateFormatter} from 'utils/dateFormatter'
import {getScreeningSelector} from 'selectors/screeningSelectors'
import {systemCodeDisplayValue, getAddressCountiesSelector} from 'selectors/systemCodeSelectors'
import {isFutureDatetimeCreate, combineCompact} from 'utils/validator'

export const getIncidentDateSelector = createSelector(
  getScreeningSelector,
  (screening) => dateFormatter(screening.get('incident_date', ''))
)

export const getIncidentCountySelector = createSelector(
  getScreeningSelector,
  getAddressCountiesSelector,
  (screening, addressCounties) =>
    systemCodeDisplayValue(screening.get('incident_county', ''), addressCounties) || ''
)

export const getAddressSelector = createSelector(
  getScreeningSelector,
  (store) => US_STATE.find((usState) => usState.code === store.getIn(['screening', 'incident_address', 'state'])),
  (screening, usState) => Map({
    city: screening.getIn(['incident_address', 'city'], '') || '',
    street_address: screening.getIn(['incident_address', 'street_address'], '') || '',
    state: usState ? usState.name : '',
    zip: screening.getIn(['incident_address', 'zip'], '') || '',
  })
)

export const getLocationTypeSelector = createSelector(
  getScreeningSelector,
  (screening) => screening.get('location_type', '')
)

export const getErrorsSelector = createSelector(
  (state) => state.getIn(['screening', 'incident_date']),
  (incident_date) => (fromJS({
    incident_date: combineCompact(isFutureDatetimeCreate(incident_date, 'The incident date and time cannot be in the future.')),
  }))
)
