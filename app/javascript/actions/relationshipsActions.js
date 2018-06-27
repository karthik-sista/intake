import {
  FETCH_RELATIONSHIPS,
  FETCH_RELATIONSHIPS_COMPLETE,
  CLEAR_RELATIONSHIPS,
  MARK_PERSON_OLD,
} from 'actions/actionTypes'

export function clearRelationships() {
  return {type: CLEAR_RELATIONSHIPS}
}
export function fetchRelationshipsSuccess(relationships) {
  return {type: FETCH_RELATIONSHIPS_COMPLETE, payload: {relationships}}
}
export function fetchRelationshipsFailure(error) {
  return {type: FETCH_RELATIONSHIPS_COMPLETE, payload: {error}, error: true}
}
export function fetchRelationships(ids) {
  return {type: FETCH_RELATIONSHIPS, payload: {ids}}
}
export function markPersonOld(person) {
  return {type: MARK_PERSON_OLD, payload: {person}}
}
