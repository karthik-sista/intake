import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'
import {submitScreening} from 'actions/screeningActions'
import {
  getAllCardsAreSavedValueSelector,
  getScreeningHasErrorsSelector,
  getPeopleHaveErrorsSelector,
} from 'selectors/screening/screeningPageSelectors'
import {getScreeningIsReadOnlySelector} from 'selectors/screeningSelectors'
import SubmitButton from 'views/screenings/SubmitButton'

function mapStateToProps(state) {
  return {
    editable: !getScreeningIsReadOnlySelector(state),
    disableSubmitButton: !getAllCardsAreSavedValueSelector(state) ||
      getScreeningHasErrorsSelector(state) ||
      getPeopleHaveErrorsSelector(state),
  }
}

function mapDispatchToProps(dispatch) {
  const actions = {
    submitScreening
  }
  return bindActionCreators(actions, dispatch)
}

export default connect(mapStateToProps, mapDispatchToProps)(SubmitButton)
