import React from 'react'
import PropTypes from 'prop-types'
import CheckboxField from 'common/CheckboxField'
import DateField from 'common/DateField'
import {RELATIONSHIP_TYPES} from 'enums/RelationshipTypes'
import {GENDERS_LEGACY} from 'enums/Genders'

const isAbsentParentDisabled = (type) => (
  !type.toLowerCase().match(/\bfather\b|\bmother\b|\bparent\b/)
)
const findTypeLabel = (typeCode) => {
  const types = (RELATIONSHIP_TYPES.find((type) => type.value === typeCode).label).split('/')
  return {
    secondary: types.pop(),
    index: types.pop(),
  }
}
const EditRelationshipForm = ({onChange, person, relationship}) => {
  const type = findTypeLabel(relationship.type_code)

  return (
    <div>
      <table className='table'>
        <thead>
          <tr>
            <th className='col-md-3'>Person 1</th>
            <th className='col-md-6'>
              Relationship
              <div className='text-helper'>
                Person 1/ Person 2
              </div>
            </th>
            <th className='col-md-3'>Person 2</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>
              <ul className='unstyled-list'>
                <li>{person.name}</li>
                <li>{person.age}</li>
                <li>{GENDERS_LEGACY[person.gender] || ''}</li>
              </ul>
            </td>
            <td>
              <select
                id='edit_relationship'
                label='Relationship Type'
                value={relationship.type_code}
                aria-label='Relationship Type'
                onChange={({target}) => onChange('type_code', target.value)}
              >
                <option key=''/>
                {RELATIONSHIP_TYPES.map((relationship) =>
                  <option key={relationship.value} value={relationship.value}>
                    {relationship.label}
                  </option>
                )}
              </select>
            </td>
            <td>
              <ul className='unstyled-list'>
                <li>{relationship.name}</li>
                <li>{relationship.age}</li>
                <li>{GENDERS_LEGACY[relationship.gender]}</li>
              </ul>
            </td>
          </tr>
        </tbody>
      </table>
      <div className='row gap-top pad-left'>
        <div className='col-md-12'>
          <span>
            <b>{person.name}</b> is the {type.index} of {type.secondary} <b>{relationship.name}</b>
          </span>
        </div>
      </div>
      <div className='row pad-left'>
        <div className='col-md-4'>
          <CheckboxField
            checked={relationship.same_home_code === 'Y'}
            id='same_home_code'
            label='Live at the Same Location'
            onChange={({target}) => {
              onChange('same_home_code', (target.value === 'Y') ? 'N' : 'Y')
            }}
            value={relationship.same_home_code}
          />
        </div>
        <div className='col-md-4'>
          <CheckboxField
            checked={relationship.absent_parent_code === 'Y'}
            disabled={isAbsentParentDisabled(type.secondary)}
            id='absent_parent_code'
            label='Parents Whereabouts Unknown'
            onChange={({target}) => {
              onChange('absent_parent_code', (target.value === 'Y') ? 'N' : 'Y')
            }}
            value={relationship.absent_parent_code}
          />
        </div>
      </div>
      <div className='row pad-left'>
        <DateField
          gridClassName='col-md-4'
          id='relationship_start_date'
          label='Start Date'
          value={''}
          onChange={({target}) => onChange('start_date', (target.value))}
          hasTime={false}
        />
        <DateField
          gridClassName='col-md-4'
          id='relationship_end_date'
          label='End Date'
          value={''}
          onChange={({target}) => onChange('end_date', (target.value))}
          hasTime={false}
        />
      </div>
    </div>
  )
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

EditRelationshipForm.propTypes = {
  onChange: PropTypes.func,
  person: personPropType,
  relationship: relationshipPropType,
}

export default EditRelationshipForm
