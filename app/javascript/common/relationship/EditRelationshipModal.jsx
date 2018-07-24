import React, {Component} from 'react'
import PropTypes from 'prop-types'
import EditRelationshipForm from 'common/relationship/EditRelationshipForm'
import {ModalComponent} from 'react-wood-duck'

export class EditRelationshipModal extends Component {
  constructor(props) {
    super(props)
    this.state = {
      person: {},
      relationship: {},
    }
    this.onChange = this.onChange.bind(this)
  }

  componentDidMount() {
    this.update()
  }

  update() {
    const {person, relationship} = this.props

    if (this.state.relationship !== this.props.relationship) {
      this.setState({person: person, relationship: relationship})
    }
  }

  onChange(field, value) {
    this.setState({relationship: {...this.state.relationship, [field]: value}})
  }

  renderBody() {
    return (
      <EditRelationshipForm
        onChange={this.onChange}
        person={this.state.person}
        relationship={this.state.relationship}
      />
    )
  }

  renderFooter() {
    return (
      <div className='row'>
        <div className='col-md-12'>
          <div className='pull-right'>
            <button className='btn btn-default' onClick={this.props.closeModal}>
              Cancel
            </button>
            <button className='btn btn-primary' onClick={this.props.onChange}>
              Save Relationship
            </button>
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
        modalBody={this.renderBody()}
        modalFooter={this.renderFooter()}
        modalSize='large'
        modalTitle='Edit Relationship Type'
      />
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

EditRelationshipModal.propTypes = {
  closeModal: PropTypes.func.isRequired,
  onChange: PropTypes.func,
  person: personPropType,
  relationship: relationshipPropType,
  show: PropTypes.bool.isRequired,
}

export default EditRelationshipModal
