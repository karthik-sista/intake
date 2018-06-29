import {connect} from 'react-redux'
import {markPersonOld} from 'actions/personCardActions'
import ScreeningCreateRelationship from 'views/ScreeningCreateRelationship'

const mapDispatchToProps = (dispatch) => ({
  markThisPersonOld: (person) => {
    dispatch(markPersonOld(person))
  }  
})
export default connect(null,mapDispatchToProps)(ScreeningCreateRelationship)