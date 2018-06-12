import {connect} from 'react-redux'
import Screening from 'views/Screening'
import {bindActionCreators} from 'redux'
import {
  getScreeningTitleSelector,
  getScreeningIsReadOnlySelector
} from 'selectors/screeningSelectors'
import {
  getScreeningSubmissionErrorsSelector,
  getApiValidationErrorsSelector
} from 'selectors/errorsSelectors'
import {
  fetchHistoryOfInvolvements,
  clearHistoryOfInvolvement,
} from 'actions/historyOfInvolvementActions'
import {clearRelationships} from 'actions/relationshipsActions'
import {clearScreening} from 'actions/screeningActions'
import {clearPeople} from 'actions/personCardActions'

function mapStateToProps(state, ownProps) {
  const { params: id } = ownProps
  return {
    screeningTitle: getScreeningTitleSelector(state),
    screeningId: id,
    editable: !getScreeningIsReadOnlySelector(state),
    referralId: state.getIn(['screening', 'referral_id']),
    hasApiValidationErrors: Boolean(getApiValidationErrorsSelector(state).size),
    submitReferralErrors: getScreeningSubmissionErrorsSelector(state).toJS(),
    participantIds: state.get('participants').map((particpant) => (participant.get('id'))).toJS(),
    mode: state.getIn(['screeningPage', 'mode']),
  }
}

function mapDispatchToProps(dispatch) {
  return bindActionCreators({
    setPageMode,
    fetchHistoryOfInvolvements,
    fetchScreening,
    clearHistoryOfInvolvement,
    clearRelationships,
    clearPeople,
    clearScreening,
  }, dispatch)
}

function mergeProps(stateProps, dispatchProps, ownProps) {
  return {
    actions: {
      startScreening: () => {
        const {
          setPageMode,
          fetchHistoryOfInvolvements,
          fetchScreening,
        } = dispatchProps
        const {mode, id} = stateProps
        setPageMode(mode || 'show')
        fetchScreening(id)
        fetchHistoryOfInvolvements('screenings', id)
      },
      clearScreening: () => {
        const {
          clearHistoryOfInvolvement,
          clearRelationships,
          clearPeople,
          clearScreening,
        } = dispatchProps
        clearHistoryOfInvolvement()
        clearRelationships()
        clearPeople()
        clearScreening()
      },
    },
    ...stateProps,
    ...ownProps,
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(Screening)
