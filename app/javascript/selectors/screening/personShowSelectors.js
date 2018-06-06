import {List, Map, fromJS} from 'immutable'
import GENDERS from 'enums/Genders'
import legacySourceFormatter from 'utils/legacySourceFormatter'
import nameFormatter from 'utils/nameFormatter'
import ssnFormatter from 'utils/ssnFormatter'
import {dateFormatter} from 'utils/dateFormatter'
import {flagPrimaryLanguage} from 'common/LanguageInfo'
import US_STATE from 'enums/USState'
import {isRequiredIfCreate, combineCompact} from 'utils/validator'
import {getAddressTypes, systemCodeDisplayValue} from 'selectors/systemCodeSelectors'
import {phoneNumberFormatter} from 'utils/phoneNumberFormatter'
import {getSSNErrors} from 'utils/ssnValidator'
import {getZIPErrors} from 'utils/zipValidator'
import moment from 'moment'

const getPersonSelector = (state, personId) =>
  state.get('participants').find((person) => person.get('id') === personId) || Map()

export const getNamesRequiredSelector = (state, personId) => {
  const person = getPersonSelector(state, personId)
  const roles = person.get('roles', List())
  return (roles.includes('Victim') || roles.includes('Collateral'))
}

const getAlertMessageByRole = (roles) => {
  if (roles.includes('Victim')) {
    return 'Alleged victims must be identified with a name, even Doe or Unknown, and must be under the age of 18'
  } else if (roles.includes('Collateral')) {
    return 'Collateral must be identified with a name, even Doe or Unknown.'
  }
  return undefined
}

export const getPersonAlertErrorMessageSelector = (state, personId) => {
  const required = getNamesRequiredSelector(state, personId)
  const person = getPersonSelector(state, personId)
  const lastName = person.get('last_name')
  const firstName = person.get('first_name')
  const roles = person.get('roles', List())
  if (required && !(firstName && lastName)) {
    return getAlertMessageByRole(roles)
  }
  return undefined
}

const calculateAgeFromScreeningDate = (state, personId) => {
  const screeningStartDate = moment(state.getIn(['screeningInformationForm', 'started_at', 'value']))
  const person = getPersonSelector(state, personId)
  const dateOfBirth = person.get('date_of_birth') || ''
  const approximateAge = parseInt(person.get('approximate_age'), 10)
  const approximateAgeUnit = person.get('approximate_age_units')

  let ageFromScreeningDate

  if (dateOfBirth) {
    ageFromScreeningDate = screeningStartDate.diff(moment(dateOfBirth, 'MM/DD/YYYY'), 'years')
  } else if (approximateAge && approximateAgeUnit) {
    ageFromScreeningDate = moment().diff(screeningStartDate, 'years') + moment.duration(approximateAge, approximateAgeUnit).asYears()
  }

  return ageFromScreeningDate
}

const ageFromScreeningDateIsEmpty = (state, personId) => {
  const ageFromScreeningDate = calculateAgeFromScreeningDate(state, personId)

  return typeof ageFromScreeningDate !== 'number'
}
const isOver18YearsOfAgeAtScreeningDate = (state, personId) => {
  const ageFromScreeningDate = calculateAgeFromScreeningDate(state, personId)
  const ageLimit = 18
  return ageFromScreeningDate && ageFromScreeningDate >= ageLimit
}

const getNameErrors = (firstName, lastName, roles) => combineCompact(
  isRequiredIfCreate(firstName, 'Please enter a first name.', () => (roles.includes('Victim') || roles.includes('Collateral'))),
  isRequiredIfCreate(lastName, 'Please enter a last name.', () => (roles.includes('Victim') || roles.includes('Collateral')))
)

const getRoleErrors = (state, personId, roles) => combineCompact(
  () => {
    if (roles.includes('Victim') && (ageFromScreeningDateIsEmpty(state, personId) || isOver18YearsOfAgeAtScreeningDate(state, personId))) {
      return 'Alleged victims must be under 18 years old.'
    } else {
      return undefined
    }
  }
)

export const getErrorsSelector = (state, personId) => {
  const person = getPersonSelector(state, personId)
  const ssn = person.get('ssn') || ''
  const ssnWithoutHyphens = ssn.replace(/-|_/g, '')
  const lastName = person.get('last_name')
  const firstName = person.get('first_name')
  const addressZip =
  person.get('addresses') === undefined ? [] : person.get('addresses')
    .filter((address) => !address.get('legacy_id'))
    .map((newAddress) => (
      getZIPErrors(newAddress.get('zip'))
    )).flatten()
  const roles = person.get('roles', List())
  return fromJS({
    name: getNameErrors(firstName, lastName, roles),
    roles: getRoleErrors(state, personId, roles),
    ssn: getSSNErrors(ssnWithoutHyphens),
    addressZip,
  })
}

const getPersonRaces = (person) => person.get('races') || List()

const getRaces = (person) => {
  const personRaces = getPersonRaces(person).map((raceInformation) => {
    const race = raceInformation.get('race')
    const raceDetail = raceInformation.get('race_detail')
    const raceDetailText = raceDetail ? ` - ${raceDetail}` : ''
    return `${race}${raceDetailText}`
  })

  const races = Maybe.of(personRaces)
    .map((races) => races.map(Maybe.of))
    .map((races) => races.update(0, (maybe) => maybe.map((value) => (value + ' (primary)'))))
    .map((races) => races.map((maybe) => maybe.valueOrElse('').join(', ')))
    .valueOrElse('')

  return races
}

const getEthnicity = (person) => {
  const {hispanic_latino_origin: hispanicLatinoOrigin, ethnicity_detail} = person.toJS().ethnicity || {}

  if (!hispanicLatinoOrigin) { return undefined }

  const ethnicityText = ethnicity_detail.length > 0 ? `${ethnicity_detail} - ` : ''
  return `${ethnicityText}${hispanicLatinoOrigin}`
}

export const getFormattedPersonInformationSelector = (state, personId) => {
  const person = getPersonSelector(state, personId)
  const legacyDescriptor = person.get('legacy_descriptor')
  const showApproximateAge = !person.get('date_of_birth') && person.get('approximate_age')
  const approximateAge = showApproximateAge ?
    [person.get('approximate_age'), person.get('approximate_age_units')].join(' ') : undefined
  const dateOfBirth = person.get('date_of_birth') && dateFormatter(person.get('date_of_birth'))

  return fromJS({
    approximateAge: approximateAge,
    CSECTypes: person.get('csec_types'),
    csecStartedAt: person.get('csec_started_at') && dateFormatter(person.get('csec_started_at')),
    csecEndedAt: person.get('csec_ended_at') && dateFormatter(person.get('csec_ended_at')),
    dateOfBirth: dateOfBirth,
    ethnicity: getEthnicity(person),
    gender: GENDERS[person.get('gender')],
    languages: person.get('languages') && flagPrimaryLanguage((person.toJS().languages) || []).join(', '),
    legacySource: legacyDescriptor && legacySourceFormatter(legacyDescriptor.toJS()),
    name: {value: nameFormatter(person.toJS()), errors: [], required: false},
    races: getRaces(person),
    roles: {value: person.get('roles', List()), errors: []},
    ssn: {value: ssnFormatter(person.get('ssn')), errors: []},
    alertErrorMessage: getPersonAlertErrorMessageSelector(state, personId),
  })
}

export const getFormattedPersonWithErrorsSelector = (state, personId) => {
  const errors = getErrorsSelector(state, personId)
  return getFormattedPersonInformationSelector(state, personId)
    .setIn(['ssn', 'errors'], errors.get('ssn'))
    .setIn(['name', 'errors'], errors.get('name'))
    .setIn(['name', 'required'], getNamesRequiredSelector(state, personId))
    .setIn(['roles', 'errors'], errors.get('roles'))
}
export const getPersonFormattedPhoneNumbersSelector = (state, personId) => (
  state.get('participants', List()).find((person) => person.get('id') === personId)
    .get('phone_numbers', List()).map((phoneNumber) => (
      Map({
        number: phoneNumberFormatter(phoneNumber.get('number')),
        type: phoneNumber.get('type'),
      })
    )
    )
)

const formattedState = (stateCode) => {
  const state = US_STATE.find((state) => state.code === stateCode)
  return state ? state.name : ''
}

export const getAllPersonFormattedAddressesSelector = (state, personId) => (
  state.get('participants', List()).find((person) => person.get('id') === personId)
    .get('addresses', List()).map((address) =>
      Map({
        street: address.get('street_address'),
        city: address.get('city'),
        state: formattedState(address.get('state')),
        zip: address.get('zip'),
        zipError: address.get('legacy_id') ? null : getZIPErrors(address.get('zip')),
        type: systemCodeDisplayValue(address.get('type'), getAddressTypes(state)) || address.get('type'),
        legacy_id: address.get('legacy_id'),
      })
    )
)

export const getReadOnlyPersonFormattedAddressesSelector = (state, personId) => (
  getAllPersonFormattedAddressesSelector(state, personId)
).filter((address) => address.get('legacy_id')).map((address) => address.delete('zipError'))
