import PropTypes from 'prop-types'
import React from 'react'
import PageHeader from 'common/PageHeader'
import ScreeningSideBar from 'containers/screenings/ScreeningSideBarContainer'
import SubmitButton from 'containers/screenings/SubmitButtonContainer'
import PersonSearchCard from 'views/PersonSearch'
import PersonCardView from 'screenings/PersonCardView'
import NarrativeFormContainer from 'containers/screenings/NarrativeFormContainer'
import NarrativeShowContainer from 'containers/screenings/NarrativeShowContainer'
import IncidentInformationFormContainer from 'containers/screenings/IncidentInformationFormContainer'
import AllegationsFormContainer from 'containers/screenings/AllegationsFormContainer'
import AllegationsShowContainer from 'containers/screenings/AllegationsShowContainer'
import IncidentInformationShowContainer from 'containers/screenings/IncidentInformationShowContainer'
import WorkerSafetyFormContainer from 'containers/screenings/WorkerSafetyFormContainer'
import WorkerSafetyShowContainer from 'containers/screenings/WorkerSafetyShowContainer'
import CrossReportFormContainer from 'containers/screenings/CrossReportFormContainer'
import CrossReportShowContainer from 'containers/screenings/CrossReportShowContainer'
import DecisionFormContainer from 'containers/screenings/DecisionFormContainer'
import DecisionShowContainer from 'containers/screenings/DecisionShowContainer'
import ScreeningInformationFormContainer from 'containers/screenings/ScreeningInformationFormContainer'
import ScreeningInformationShowContainer from 'containers/screenings/ScreeningInformationShowContainer'
import HistoryOfInvolvementContainer from 'containers/screenings/HistoryOfInvolvementContainer'
import HistoryTableContainer from 'containers/screenings/HistoryTableContainer'
import EmptyHistory from 'views/history/EmptyHistory'
import CardContainer from 'containers/screenings/CardContainer'
import RelationshipsCardContainer from 'screenings/RelationshipsCardContainer'
import {Link} from 'react-router'

export default class Screening extends React.Component {
  constructor(props, context) {
    super(props, context)
  }

  componentDidMount() {
    this.props.actions.startScreening()
  }

  componentWillUnmount() {
    this.props.actions.clearScreening()
  }

  render() {
    const {
      screeningTitle,
      screeningId,
      editable,
      referralId,
      hasApiValidationErrors,
      submitReferralErrors,
      participantIds,
      mode,
    } = this.props
    return (
      <div>
        <div>
          <PageHeader
            pageTitle={screeningTitle}
            button={<SubmitButton />}
          />
        </div>
        <div className='container'>
          <div className='row'>
            <ScreeningSideBar/>
            <div className='col-xs-8 col-md-9'>
              <h1>{referralId && `Referral #${referralId}`}</h1>
              {hasApiValidationErrors && <ErrorDetail errors={submitReferralErrors} />}
              <CardContainer
                title='Screening Information'
                id='screening-information-card'
                edit={<ScreeningInformationFormContainer />}
                show={<ScreeningInformationShowContainer />}
              />
              { editable && <PersonSearchCard /> }
              {participantIds.map(({id}) => <PersonCardView key={id} personId={id} />)}
              <CardContainer
                title='Narrative'
                id='narrative-card'
                edit={<NarrativeFormContainer />}
                show={<NarrativeShowContainer />}
              />
              <CardContainer
                title='Incident Information'
                id='incident-information-card'
                edit={<IncidentInformationFormContainer />}
                show={<IncidentInformationShowContainer />}
              />
              <CardContainer
                title='Allegations'
                id='allegations-card'
                edit={<AllegationsFormContainer />}
                show={<AllegationsShowContainer />}
              />
              <RelationshipsCardContainer />
              <CardContainer
                title='Worker Safety'
                id='worker-safety-card'
                edit={<WorkerSafetyFormContainer />}
                show={<WorkerSafetyShowContainer />}
              />
              <HistoryOfInvolvementContainer empty={<EmptyHistory />} notEmpty={<HistoryTableContainer />} />
              <CardContainer
                title='Cross Report'
                id='cross-report-card'
                edit={<CrossReportFormContainer />}
                show={<CrossReportShowContainer />}
              />
              <CardContainer
                title='Decision'
                id='decision-card'
                edit={<DecisionFormContainer />}
                show={<DecisionShowContainer />}
              />
              {
                mode === 'show' &&
              <div>
                <Link to='/' className='gap-right'>Home</Link>
                {editable && <Link to={`/screenings/${screeningId}/edit`}>Edit</Link>}
              </div>
              }
            </div>
          </div>
        </div>
      </div>
    )
  }
}
