import {createSelector} from 'reselect'
import {Map, List} from 'immutable'
import nameFormatter from 'utils/nameFormatter'
import {selectParticipants} from 'selectors/participantSelectors'
import {systemCodeDisplayValue, getRelationshipTypesSelector} from 'selectors/systemCodeSelectors'

export const getScreeningRelationships = (state) => (state.get('relationships', List()))

const isPersonCardExists = (people, relationship) => {
  if (people && people.size > 0 && relationship.legacy_descriptor) {
    const isLegacyIdSame = people.some((person) => person.get('legacy_id') === relationship.legacy_descriptor.legacy_id)
    return !isLegacyIdSame
  }
  return true
}

const isPersonNewlyCreated = (participants, person) => {
  if (participants.size > 0 && person.legacy_descriptor) {
    const personNewlyCreated = participants.some((participant) => { 
      return participant.get('legacy_id') === person.legacy_descriptor.legacy_id && participant.get('newly_created_person') })
    return personNewlyCreated
  }
  return false
}

export const getPeopleSelector = createSelector(
  selectParticipants,
  getScreeningRelationships,
  getRelationshipTypesSelector,
  (participants, people, relationshipTypes) => people.map((person) => Map({
    name: nameFormatter({...person.toJS()}),
    newly_created_person: isPersonNewlyCreated(participants, person.toJS()),
    relationships: person.get('relationships', List()).map((relationship) => (
      Map({
        name: nameFormatter({
          first_name: relationship.get('related_person_first_name'),
          last_name: relationship.get('related_person_last_name'),
          middle_name: relationship.get('related_person_middle_name'),
          name_suffix: relationship.get('related_person_name_suffix'),
        }),
        legacy_descriptor: relationship.get('legacy_descriptor'),
        type: systemCodeDisplayValue(relationship.get('indexed_person_relationship'), relationshipTypes),
        secondaryRelationship: systemCodeDisplayValue(relationship.get('related_person_relationship'), relationshipTypes),
        person_card_exists: isPersonCardExists(participants, relationship.toJS()),
      })
    )),
  }))
)
