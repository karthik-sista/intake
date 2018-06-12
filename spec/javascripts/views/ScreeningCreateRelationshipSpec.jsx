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
})
