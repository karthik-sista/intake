import React from 'react'
import {shallow} from 'enzyme'
import ScreeningCreateRelationship from 'views/ScreeningCreateRelationship'

describe('ScreeningCreateRelationship', () => {
  const wrapper = shallow(<ScreeningCreateRelationship />)

  it('has a button', () => {
    expect(wrapper.find('button').length).toBe(1)
  })
  it('has a ModalComponent', () => {
    expect(wrapper.find('ModalComponent').length).toBe(1)
  })

  it('simulate a click on button and show modal', () => {
    wrapper.find('button').simulate('click')
    expect(wrapper.instance().state.show).toBe(true)
  })

  it('closes the modal', () => {
    wrapper.instance().closeModal()
    expect(wrapper.instance().state.show).toEqual(false)
  })
})