import React, {Component} from 'react'
import PropTypes from 'prop-types'
import AttachLink from 'common/relationship/AttachLink'
import EditRelationshipModal from 'common/relationship/EditRelationshipModal'

export class ActionMenu extends Component {
  constructor(props) {
    super(props)
    this.state = {show: false}
    this.closeModal = this.closeModal.bind(this)
    this.handleShowModal = this.handleShowModal.bind(this)
  }

  closeModal() {
    this.setState({show: false})
  }

  handleShowModal() {
    this.setState({show: true})
  }

  renderModal() {
    const {onChange, person, relationship} = this.props

    return (
      <EditRelationshipModal
        closeModal={this.closeModal}
        onChange={onChange}
        person={person}
        relationship={relationship}
        show={this.state.show}
      />
    )
  }

  render() {
    return (
      <div>
        <div className='dropdown' aria-label='Action Menu'>
          <span className='glyphicon glyphicon-option-vertical' type='button' data-toggle='dropdown' aria-hidden='true'/>
          <ul className='dropdown-menu dropdown-menu-right' role='menu' aria-hidden='true'>
            <li className='dropdown-header'>Actions</li>
            <li role='separator' className='divider'/>
            <li role='menuitem'><AttachLink {...this.props}/></li>
            <li role='menuitem'>
              <a className='edit-relationship' onClick={this.handleShowModal}>
                Edit Relationship
              </a>
            </li>
          </ul>
        </div>
        {this.state.show && this.renderModal()}
      </div>
    )
  }
}

const personPropType = PropTypes.shape({
  age: PropTypes.string,
  dateOfBirth: PropTypes.string,
  legacy_id: PropTypes.string,
  gender: PropTypes.string,
  name: PropTypes.string,
})
const relationshipPropType = PropTypes.shape({
  absent_parent_code: PropTypes.string,
  age: PropTypes.string,
  dateOfBirth: PropTypes.string,
  legacy_descriptor: PropTypes.object,
  gender: PropTypes.string,
  name: PropTypes.string,
  person_card_exists: PropTypes.bool,
  same_home_code: PropTypes.string,
  secondaryRelationship: PropTypes.string,
  type: PropTypes.string,
  type_code: PropTypes.string,
})

ActionMenu.propTypes = {
  isScreening: PropTypes.bool,
  onChange: PropTypes.func,
  onClick: PropTypes.func,
  pendingPeople: PropTypes.arrayOf(PropTypes.string),
  person: personPropType,
  relationship: relationshipPropType,
  screeningId: PropTypes.string,
}

export default ActionMenu
