import React, {Component} from 'react'
import PropTypes from 'prop-types'
import EditRelationshipForm from 'common/relationship/EditRelationshipForm'
import {ModalComponent} from 'react-wood-duck'

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
const propTypes = {
  closeModal: PropTypes.func.isRequired,
  onChange: PropTypes.func,
  person: personPropType,
  relationship: relationshipPropType,
  show: PropTypes.bool.isRequired,
}

export class EditRelationshipModal extends Component {
  constructor(props) {
    super(props)
  }

  renderEditRelationshipForm() {
    const {onChange, person, relationship} = this.props

    return <EditRelationshipForm onChange={onChange} person={person} relationship={relationship}/>
  }

  renderFooter() {
    const {closeModal} = this.props
    return (
      <div className='row'>
        <div className='col-md-12'>
          <div className='pull-right'>
            <button className='btn btn-default' onClick={closeModal}>Cancel</button>
            <button className='btn btn-primary'>Save Relationship</button>
          </div>
        </div>
      </div>
    )
  }

  render() {
    const {closeModal, show} = this.props
    return (
      <ModalComponent
        closeModal={closeModal}
        showModal={show}
        modalBody={this.renderEditRelationshipForm()}
        modalFooter={this.renderFooter()}
        modalSize='large'
        modalTitle='Edit Relationship Type'
      />
    )
  }
}

EditRelationshipModal.propTypes = propTypes

export default EditRelationshipModal
