import {createSelector} from 'reselect'
import {List, Map, fromJS} from 'immutable'
import {getScreeningSelector} from 'selectors/screeningSelectors'
import SCREENING_DECISION from 'enums/ScreeningDecision'
import SCREENING_DECISION_OPTIONS from 'enums/ScreeningDecisionOptions'
import {isRequiredCreate, isRequiredIfCreate, combineCompact} from 'utils/validator'
import {getRolesSelector} from './decisionFormSelectors'

export const getErrorsSelector = createSelector(
  (state) => state.getIn(['screening', 'screening_decision']),
  (state) => state.getIn(['screening', 'screening_decision_detail']),
  (state) => state.getIn(['screening', 'access_restrictions']) || '',
  (state) => state.getIn(['screening', 'restrictions_rationale']) || '',
  (state) => state.get('allegationsForm', List()),
  getRolesSelector,
  (state) => state.getIn(['screening', 'additional_information']) || '',
  (decision, decisionDetail, accessRestrictions, restrictionsRationale, allegations, roles, additionalInformation) => (
    fromJS({
      screening_decision: combineCompact(
        isRequiredCreate(decision, 'Please enter a decision'),
        () => (
          (decision === 'promote_to_referral' &&
            allegations.every((allegation) => allegation.get('allegationTypes').isEmpty())) ?
            'Please enter at least one allegation to promote to referral.' : undefined
        ),
        () => (
          (decision === 'information_to_child_welfare_services' &&
            roles.every((role) => (role !== 'Mandated Reporter') && (role !== 'Non-mandated Reporter') && (role !== 'Anonymous Reporter'))) ?
            'A reporter is required to submit a screening Contact' : undefined
        )
      ),
      screening_decision_detail: combineCompact(
        () => ((decision === 'promote_to_referral' && !decisionDetail) ? 'Please enter a response time' : undefined)
      ),
      additional_information: combineCompact(
        isRequiredIfCreate(additionalInformation, 'Please enter additional information', () => (
          decision === 'screen_out' && decisionDetail === 'evaluate_out'
        ))
      ),
      restrictions_rationale: combineCompact(
        isRequiredIfCreate(restrictionsRationale, 'Please enter an access restriction reason', () => (accessRestrictions))
      ),
    })
  )
)

export const getAdditionalInfoRequiredSelector = createSelector(
  (state) => state.getIn(['screening', 'screening_decision']),
  (state) => state.getIn(['screening', 'screening_decision_detail']),
  (decision, decisionDetail) => (decision && decisionDetail && decision === 'screen_out' && decisionDetail === 'evaluate_out')
)

export const getDecisionSelector = createSelector(
  getScreeningSelector,
  getErrorsSelector,
  (screening, errors) => (
    Map({
      value: SCREENING_DECISION[screening.get('screening_decision')],
      errors: errors.get('screening_decision'),
    })
  )
)

export const getDecisionDetailSelector = createSelector(
  getScreeningSelector,
  getErrorsSelector,
  (screening, errors) => {
    const decision = screening.get('screening_decision')
    let decisionDetail = screening.get('screening_decision_detail')

    if (['promote_to_referral', 'screen_out'].includes(decision)) {
      decisionDetail = SCREENING_DECISION_OPTIONS[decision].values[decisionDetail]
    }
    return Map({
      value: decisionDetail,
      label: SCREENING_DECISION_OPTIONS[decision] ? SCREENING_DECISION_OPTIONS[decision].label : '',
      errors: errors.get('screening_decision_detail'),
      required: decision === 'promote_to_referral',
    })
  }
)

export const getRestrictionRationaleSelector = createSelector(
  (state) => state.getIn(['screening', 'restrictions_rationale']),
  (state) => getErrorsSelector(state).get('restrictions_rationale'),
  (value, errors) => Map({value: value || '', errors})
)

export const getAdditionalInformationSelector = createSelector(
  (state) => state.getIn(['screening', 'additional_information']),
  (state) => getErrorsSelector(state).get('additional_information'),
  (value, errors) => Map({value: value || '', errors})
)
