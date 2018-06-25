import {takeLatest, put, call, select} from 'redux-saga/effects'
import {STATUS_CODES, post} from 'utils/http'
import {
  CREATE_PERSON,
  createPersonSuccess,
  createPersonFailure,
} from 'actions/personCardActions'
import {fetchHistoryOfInvolvements} from 'actions/historyOfInvolvementActions'
import {fetchRelationships} from 'actions/relationshipsActions'
import {selectClientIds} from 'selectors/participantSelectors'
import {getScreeningIdValueSelector} from 'selectors/screeningSelectors'

export function* sendPersonPayload(person) {
  const {screening_id, legacy_descriptor, sealed, sensitive} = person
  const {legacy_id, legacy_source_table} = legacy_descriptor || {}
  const participantPayload = {
    participant: {
      screening_id,
      legacy_descriptor: {
        legacy_id,
        legacy_table_name: legacy_source_table,
      },
      sealed: sealed || false,
      sensitive: sensitive || false,
    },
  }
  return yield call(post, '/api/v1/participants', participantPayload)
}

function markNewlyCreatedPerson(person) {
  const newlyCreatePerson = {... person, newly_created_person: true}
  console.log(`in function newlycreatedperson ${newlyCreatePerson}`)
  return newlyCreatePerson
}
export function* createParticipant({payload: {person}}) {
  try {
    let response = yield* sendPersonPayload(person)
    response = markNewlyCreatedPerson(response)
    yield put(createPersonSuccess(response))
    const clientIds = yield select(selectClientIds)
    const fetchedRelationships = fetchRelationships(clientIds)
    yield put(fetchedRelationships)
    const screeningId = yield select(getScreeningIdValueSelector)
    yield put(fetchHistoryOfInvolvements('screenings', screeningId))
  } catch (error) {
    if (error.status === STATUS_CODES.forbidden) {
      yield call(alert, 'You are not authorized to add this person.')
    } else {
      yield put(createPersonFailure(error.responseJSON))
    }
  }
}
export function* createParticipantSaga() {
  yield takeLatest(CREATE_PERSON, createParticipant)
}
