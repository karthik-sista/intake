import {connect} from 'react-redux'
import ScreeningSideBar from 'screenings/ScreeningSideBar'

function mapStateToProps(state) {
  return {
    participants: state.get('participants').toJS(),
  }
}

export default connect(mapStateToProps)(ScreeningSideBar)
