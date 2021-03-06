import {takeEvery, put, call, select} from 'redux-saga/effects'
import {destroy} from 'utils/http'
import {
  DELETE_PERSON,
  deletePersonSuccess,
  deletePersonFailure,
} from 'actions/personCardActions'
import {fetchHistoryOfInvolvements} from 'actions/historyOfInvolvementActions'
import {fetchRelationships} from 'actions/relationshipsActions'
import {fetch as fetchAllegations} from 'actions/screeningAllegationsActions'
import {selectClientIds} from 'selectors/participantSelectors'
import {getScreeningIdValueSelector} from 'selectors/screeningSelectors'

export function* deleteParticipant({payload: {id}}) {
  try {
    const screeningId = yield select(getScreeningIdValueSelector)
    yield call(destroy, `/api/v1/screenings/${screeningId}/participants/${id}`)
    yield put(deletePersonSuccess(id))
    yield put(fetchAllegations(screeningId))
    const clientIds = yield select(selectClientIds)
    yield put(fetchRelationships(clientIds))
    yield put(fetchHistoryOfInvolvements('screenings', screeningId))
  } catch (error) {
    yield put(deletePersonFailure(error.responseJSON))
  }
}
export function* deleteParticipantSaga() {
  yield takeEvery(DELETE_PERSON, deleteParticipant)
}
