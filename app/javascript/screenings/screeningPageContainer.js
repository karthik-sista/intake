import {ScreeningPage} from './ScreeningPage'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'
import * as screeningActions from 'actions/screeningActions'
import * as personCardActions from 'actions/personCardActions'
import {clearRelationships} from 'actions/relationshipsActions'
import {fetchHistoryOfInvolvements, clearHistoryOfInvolvement} from 'actions/historyOfInvolvementActions'
import {setPageMode} from 'actions/screeningPageActions'
import {getScreeningSubmissionErrorsSelector, getApiValidationErrorsSelector} from 'selectors/errorsSelectors'
import {getScreeningTitleSelector, getScreeningIsReadOnlySelector} from 'selectors/screeningSelectors'
import {selectParticipants} from 'selectors/participantSelectors'
import {
  getAllCardsAreSavedValueSelector,
  getScreeningHasErrorsSelector,
  getPeopleHaveErrorsSelector,
} from 'selectors/screening/screeningPageSelectors'

function mapStateToProps(state, _ownProps) {
  return {
    disableSubmitButton: !getAllCardsAreSavedValueSelector(state) ||
        getScreeningHasErrorsSelector(state) ||
        getPeopleHaveErrorsSelector(state),
    editable: !getScreeningIsReadOnlySelector(state),
    loaded: state.getIn(['screening', 'fetch_status']) === 'FETCHED',
    mode: state.getIn(['screeningPage', 'mode']),
    participants: selectParticipants(state).toJS(),
    reference: state.getIn(['screening', 'reference']),
    referralId: state.getIn(['screening', 'referral_id']),
    hasApiValidationErrors: Boolean(getApiValidationErrorsSelector(state).size),
    screeningTitle: getScreeningTitleSelector(state),
    submitReferralErrors: getScreeningSubmissionErrorsSelector(state).toJS(),
  }
}

function mapDispatchToProps(dispatch, _ownProps) {
  const actions = {
    setPageMode,
    fetchHistoryOfInvolvements,
    clearHistoryOfInvolvement,
    clearRelationships,
    ...personCardActions,
    ...screeningActions,
  }
  return {
    actions: bindActionCreators(actions, dispatch),
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(ScreeningPage)
