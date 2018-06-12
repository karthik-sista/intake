import PersonShowContainer from 'containers/screenings/PersonShowContainer'
import React from 'react'
import {createMockStore} from 'redux-test-utils'
import {fromJS} from 'immutable'
import {shallow} from 'enzyme'

describe('PersonShowContainer', () => {
  const state = fromJS({
    participants: [{id: '1', ssn: '123456789', approximate_age: '9', approximate_age_units: 'dog years',
      csec_types: ['At Risk'], csec_started_at: '2222-02-02', csec_ended_at: '2222-02-02',
      date_of_birth: '2014-01-15', languages: ['Javascript', 'Ruby'], gender: 'female',
      roles: ['super-hero', 'anti-hero'], first_name: 'John', middle_name: 'Q', last_name: 'Public',
      legacy_descriptor: {legacy_ui_id: '1-4', legacy_table_description: 'Client'},
      races: [{race: 'White', race_detail: 'Romanian'}, {race: 'Asian', race_detail: 'Chinese'}],
      ethnicity: {hispanic_latino_origin: 'Yes', ethnicity_detail: ['Mexican']},
    }]})
  const store = createMockStore(state)
  let component
  beforeEach(() => {
    const context = {store}
    component = shallow(<PersonShowContainer personId='1'/>, {context}, {disableLifecycleMethods: true})
  })
  it('renders PersonInformationShow', () => {
    expect(component.find('PersonInformationShow').props()).toEqual({
      alertErrorMessage: undefined,
      approximateAge: undefined,
      CSECTypes: {
        value: ['At Risk'],
        errors: [],
      },
      csecStartedAt: {
        value: '02/02/2222',
        errors: [],
      },
      csecEndedAt: '02/02/2222',
      dateOfBirth: '01/15/2014',
      name: {
        value: 'John Q Public',
        errors: [],
        required: false,
      },
      ethnicity: 'Mexican - Yes',
      gender: 'Female',
      languages: 'Javascript (Primary), Ruby',
      legacySource: 'Client ID 1-4 in CWS-CMS',
      personId: '1',
      races: 'White - Romanian (primary), Asian - Chinese',
      roles: {
        value: ['super-hero', 'anti-hero'],
        errors: [],
      },
      ssn: {value: '123-45-6789', errors: []},
      showCSEC: undefined,
    })
  })
})
