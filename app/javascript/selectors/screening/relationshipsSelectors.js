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
  console.log(`1.participants ${JSON.stringify(participants)}`)
  console.log(`2.person ${JSON.stringify(person)}`)
  console.log(`2.1.participants.size ${JSON.stringify(participants.size)}`)
  console.log(`2.2.person.gender ${person.gender}`)
  console.log(`================================`)
  if (participants.size > 0 && person.legacy_descriptor) {
    console.log(`3.person.legacy_descriptor ${JSON.stringify(person.legacy_descriptor)}`)
    const personNewlyCreated = participants.some((participant) => { 
      console.log(`3.1 participant inside ${JSON.stringify(participant)}`)
      console.log(`3.2 participant.get('legacy_id') ${JSON.stringify(participant.get('legacy_id'))}`)
      console.log(`3.3 person.legacy_descriptor.legacy_id ${JSON.stringify(person.legacy_descriptor.legacy_id)}`)
      return participant.get('legacy_id') === person.legacy_descriptor.legacy_id && participant.get('newly_created_person') })
    console.log(`4.personNewlyCreated ${personNewlyCreated}`)
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
