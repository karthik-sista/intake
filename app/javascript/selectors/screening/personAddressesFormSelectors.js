import {List, Map} from 'immutable'
import {selectAddressTypes} from 'selectors/systemCodeSelectors'
import {getZIPErrors} from 'utils/zipValidator'

const getAddresses = (person) => person.get('addresses', List()).map((address) => Map({
  id: address.get('id'),
  street: address.getIn(['street', 'value']),
  city: address.getIn(['city', 'value']),
  state: address.getIn(['state', 'value']),
  zip: address.getIn(['zip', 'value']),
  type: address.getIn(['type', 'value']),
  legacy_id: address.getIn(['legacy_descriptor', 'value', 'legacy_id'], null),
}))

export const getPersonEditableAddressesSelector = (state, personId) => getAddresses(state.get('peopleForm', Map()).get(personId))
  .filter((address) => !address.get('legacy_id'))
  .map((address) => address.delete('legacy_id'))
  .map((address) => address.set('zipError', getZIPErrors(address.get('zip'))))

export const getAddressTypeOptionsSelector = (state) => selectAddressTypes(state).map((addressType) => Map({
  label: addressType.get('value'),
}))
