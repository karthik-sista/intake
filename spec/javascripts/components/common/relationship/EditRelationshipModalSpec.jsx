import React from 'react'
import {shallow} from 'enzyme'
import {ModalComponent} from 'react-wood-duck'
import EditRelationshipForm from 'common/relationship/EditRelationshipForm'
import EditRelationshipModal from 'common/relationship/EditRelationshipModal'

describe('EditRelationshipModal', () => {
  const props = {
    closeModal: () => {},
    onClick: () => {},
    person: {
      age: '20 yrs',
      legacy_id: '1',
      gender: 'M',
      name: 'Luke Skywalker',
    },
    relationship: {
      absent_parent_code: 'Y',
      name: 'Darth Vader',
      age: '30 yrs',
      gender: 'M',
      secondaryRelationship: 'Father',
      same_home_code: 'N',
      type_code: '210',
    },
    show: false,
  }
  const renderEditRelationshipModal = (props) => shallow(<EditRelationshipModal {...props}/>)

  it('renders a Modal Component', () => {
    expect(renderEditRelationshipModal(props).find(ModalComponent).length).toBe(1)
  })

  describe('renderFooter', () => {
    it('renders two buttons', () => {
      const modalRender = renderEditRelationshipModal(props).find(ModalComponent)

      expect(modalRender.shallow().find('button').length).toBe(2)
    })
  })

  describe('renderEditRelationshipForm', () => {
    const modalRender = renderEditRelationshipModal(props).find(ModalComponent)
    it('renders the EditRelationshipForm', () => {
      expect(modalRender.shallow().find(EditRelationshipForm).length).toBe(1)
    })

    it('passes the props to EditRelationshipForm', () => {
      const render = modalRender.shallow().find(EditRelationshipForm)

      expect(render.prop('person')).toEqual({
        age: '20 yrs',
        legacy_id: '1',
        gender: 'M',
        name: 'Luke Skywalker',
      })
      expect(render.prop('relationship')).toEqual({
        absent_parent_code: 'Y',
        name: 'Darth Vader',
        age: '30 yrs',
        gender: 'M',
        secondaryRelationship: 'Father',
        same_home_code: 'N',
        type_code: '210',
      })
    })
  })
})
