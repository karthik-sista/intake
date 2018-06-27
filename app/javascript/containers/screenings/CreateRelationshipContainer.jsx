import {connect} from 'react-redux'
import {markPersonOld} from 'actions/relationshipsActions'
import ScreeningCreateRelationship from 'views/ScreeningCreateRelationship'

const mapDispatchToProps = (dispatch) => ({
  markThisPersonOld: (person) => {
    dispatch(markPersonOld(person))
  }  
})
export default connect(null,mapDispatchToProps)(ScreeningCreateRelationship)