import React from 'react'
import {shallow} from 'enzyme'
import ActionMenu from 'common/relationship/ActionMenu'
import AttachLink from 'common/relationship/AttachLink'
import EditRelationshipModal from 'common/relationship/EditRelationshipModal'

describe('ActionMenu', () => {
  const props = {
    isScreening: true,
    onClick: () => {},
    pendingPeople: [],
    person: {
      name: 'Goku',
    },
    screeningId: '1',
    relationship: {
      absent_parent_code: 'Y',
      name: 'Gohan',
      age: '30 yrs',
      gender: 'M',
      person_card_exists: true,
      secondaryRelationship: 'Father',
      same_home_code: 'N',
      type: 'son',
      type_code: '210',
    },
  }
  const renderActionMenu = (props) => shallow(<ActionMenu {...props}/>)

  it('renders a span', () => {
    expect(renderActionMenu(props).find('span').length).toBe(1)
  })

  it('renders an unordered list', () => {
    expect(renderActionMenu(props).find('ul').length).toBe(1)
  })

  it('renders AttachLink component', () => {
    expect(renderActionMenu(props).find(AttachLink).length).toBe(1)
  })

  it('renders an Edit Relationship link', () => {
    expect(renderActionMenu(props).find('.edit-relationship').length).toBe(1)
  })

  it('renders ModalComponent', () => {
    expect(renderActionMenu(props).find(EditRelationshipModal).length).toBe(1)
  })

  describe('closeModal', () => {
    it('sets the state show to false', () => {
      const instance = renderActionMenu(props).instance()

      instance.setState({show: true})
      expect(instance.state.show).toBe(true)
      instance.closeModal()
      expect(instance.state.show).toBe(false)
    })
  })

  describe('handleShowModal', () => {
    it('sets the state show to true', () => {
      const instance = renderActionMenu(props).instance()

      expect(instance.state.show).toBe(false)
      instance.handleShowModal()
      expect(instance.state.show).toBe(true)
    })
  })
})
