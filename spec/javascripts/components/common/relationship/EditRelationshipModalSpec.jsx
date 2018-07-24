import React from 'react'
import {shallow, mount} from 'enzyme'
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
    show: true,
  }
  const renderEditRelationshipModal = (props) => shallow(<EditRelationshipModal {...props}/>)
  const renderEditRelationshipModalMount = (props) => mount(<EditRelationshipModal {...props}/>)

  describe('rendersModal', () => {
    it('renders a ModalComponent', () => {
      expect(renderEditRelationshipModal(props).find(ModalComponent).length).toBe(1)
    })
  })

  describe('renderFooter', () => {
    it('renders two buttons', () => {
      expect(
        renderEditRelationshipModal(props).find(ModalComponent).shallow().find('button').length
      ).toBe(2)
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

  describe('onChange', () => {
    it('sets the state', () => {
      const render = renderEditRelationshipModalMount(props)

      expect(render.state('relationship').same_home_code).toEqual('N')
      expect(render.state('relationship').absent_parent_code).toEqual('Y')
      expect(render.state('relationship').type_code).toEqual('210')
      render.instance().onChange('same_home_code', 'Y')
      render.instance().onChange('absent_parent_code', 'N')
      render.instance().onChange('type_code', '211')
      expect(render.state('relationship').same_home_code).toEqual('Y')
      expect(render.state('relationship').absent_parent_code).toEqual('N')
      expect(render.state('relationship').type_code).toEqual('211')
    })
  })

  describe('update', () => {
    it('sets the state with the parents props', () => {
      const render = renderEditRelationshipModalMount(props)

      expect(render.state('relationship')).toEqual({
        absent_parent_code: 'Y',
        name: 'Darth Vader',
        age: '30 yrs',
        gender: 'M',
        secondaryRelationship: 'Father',
        same_home_code: 'N',
        type_code: '210',
      })
      expect(render.state('person')).toEqual({
        age: '20 yrs',
        legacy_id: '1',
        gender: 'M',
        name: 'Luke Skywalker',
      })
    })
  })
})
