import {connect} from 'react-redux'
import {Relationships} from 'common/Relationships'
import {getPeopleSelector} from 'selectors/screening/relationshipsSelectors'
import {createPerson} from 'actions/personCardActions'
import {getScreeningIdValueSelector} from 'selectors/screeningSelectors'
import {selectParticipants} from 'selectors/participantSelectors'

const mapStateToProps = (state, _ownProps) => ({
  participants: selectParticipants(state).toJS(),
  people: getPeopleSelector(state).toJS(),
  screeningId: getScreeningIdValueSelector(state),
  isScreening: true,
  pendingPeople: state.get('pendingParticipants').toJS(),
})

const mapDispatchToProps = (dispatch) => ({
  onClick: (relationship, screeningId) => {
    const relationshipsPerson = {
      screening_id: screeningId,
      legacy_descriptor: {
        legacy_id: relationship.legacy_descriptor && relationship.legacy_descriptor.legacy_id,
        legacy_source_table: relationship.legacy_descriptor && relationship.legacy_descriptor.legacy_table_name,
      },
    }
    dispatch(createPerson(relationshipsPerson))
  },
})

export default connect(mapStateToProps, mapDispatchToProps)(Relationships)
