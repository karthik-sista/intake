import PropTypes from 'prop-types'
import React from 'react'
import {connect} from 'react-redux'
import {createSnapshot, clearSnapshot} from 'actions/snapshotActions'
import {clearPeople, createSnapshotPerson} from 'actions/personCardActions'
import {clear as clearSearch, setSearchTerm} from 'actions/peopleSearchActions'
import {clearHistoryOfInvolvement} from 'actions/historyOfInvolvementActions'
import {clearRelationships} from 'actions/relationshipsActions'
import PersonSearchFormContainer from 'containers/common/PersonSearchFormContainer'
import PersonCardView from 'snapshots/PersonCardView'
import HistoryOfInvolvementContainer from 'containers/snapshot/HistoryOfInvolvementContainer'
import HistoryTableContainer from 'containers/snapshot/HistoryTableContainer'
import EmptyHistory from 'views/history/EmptyHistory'
import RelationshipsCardContainer from 'containers/snapshot/RelationshipsCardContainer'
import PageHeader from 'common/PageHeader'
import SnapshotSideBar from 'snapshots/SnapshotSideBar'
import {selectParticipants} from 'selectors/participantSelectors'

const isDuplicatePerson = (participants, id) => (
  participants.some((x) => x.legacy_id === id)
)

export class SnapshotPage extends React.Component {
  componentDidMount() {
    this.props.createSnapshot()
  }

  componentWillUnmount() {
    this.props.unmount()
  }

  startOverButton() {
    const {startOver} = this.props
    return (
      <button type='button'
        className='btn primary-btn pull-right'
        disabled={false}
        onClick={startOver}
      >
        Start Over
      </button>
    )
  }

  onSelectPerson(person) {
    const id = person.legacyDescriptor && person.legacyDescriptor.legacy_id
    if (!isDuplicatePerson(this.props.participants, id)) {
      this.props.createSnapshotPerson(id)
    }
  }

  renderSnapshotCard() {
    return (
      <div className='card edit double-gap-bottom' id='snapshot-card'>
        <div className='card-body'>
          <div className='row'>
            <div className='col-md-12'>
              <div className='double-pad-top'>
                The Child Welfare History Snapshot allows you to search CWS/CMS for people and their past history with CWS.
                To start, search by any combination of name, date of birth, or social security number. Click on a person from
                the results to add them to the Snapshot, and their basic information and history will automatically appear below.
                You can add as many people as you like, and when ready, copy the summary of their history.
                You will need to manually paste it into a document or a field in CWS/CMS.
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  renderBody(participants) {
    return (
      <div className='col-md-9 col-xs-8 '>
        <div className='row'>
          {this.renderSnapshotCard()}
          <PersonSearchFormContainer
            onSelect={(person) => this.onSelectPerson(person)}
            searchPrompt='Search for clients'
            canCreateNewPerson={false}
          />
          {participants.map(({id}) =>
            <PersonCardView key={id} personId={id} />
          )}
          <RelationshipsCardContainer />
          <HistoryOfInvolvementContainer empty={<EmptyHistory />} notEmpty={<HistoryTableContainer />} />
        </div>
      </div>
    )
  }

  render() {
    const {participants} = this.props
    return (
      <div>
        <div>
          <PageHeader pageTitle='Snapshot' button={this.startOverButton()} />
        </div>
        <div className='container'>
          <div className='row'>
            <SnapshotSideBar participants={participants} />
            {this.renderBody(participants)}
          </div>
        </div>
      </div>
    )
  }
}

SnapshotPage.propTypes = {
  createSnapshot: PropTypes.func,
  createSnapshotPerson: PropTypes.func,
  participants: PropTypes.array,
  startOver: PropTypes.func,
  unmount: PropTypes.func,
}

const mapStateToProps = (state) => ({
  participants: selectParticipants(state).toJS(),
})

export const mapDispatchToProps = (dispatch) => ({
  createSnapshot: () => dispatch(createSnapshot()),
  createSnapshotPerson: (id) => dispatch(createSnapshotPerson(id)),
  startOver: () => {
    dispatch(createSnapshot())
    dispatch(clearPeople())
    dispatch(clearHistoryOfInvolvement())
    dispatch(clearRelationships())
    dispatch(clearSearch())
    dispatch(setSearchTerm(''))
  },
  unmount: () => {
    dispatch(clearPeople())
    dispatch(clearHistoryOfInvolvement())
    dispatch(clearRelationships())
    dispatch(clearSnapshot())
  },
})

export default connect(mapStateToProps, mapDispatchToProps)(SnapshotPage)
