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
        {this.renderModal()}
      </div>
    )
  }
}

ActionMenu.propTypes = {
  isScreening: PropTypes.bool,
  onChange: PropTypes.func,
  onClick: PropTypes.func,
  pendingPeople: PropTypes.arrayOf(PropTypes.string),
  person: PropTypes.object,
  relationship: PropTypes.object,
  screeningId: PropTypes.string,
}

export default ActionMenu
