import DateField from 'common/DateField'
import InlineHeader from 'common/InlineHeader'
import InputField from 'common/InputField'
import APPROXIMATE_AGE_UNITS from 'enums/ApproximateAgeUnits'
import GENDERS from 'enums/Genders'
import LANGUAGES from 'enums/Languages'
import PropTypes from 'prop-types'
import React from 'react'
import Select from 'react-select'
import SelectField from 'common/SelectField'

const PersonDemographicsForm = ({
  approximateAge,
  approximateAgeIsDisabled,
  approximateAgeUnit,
  dateOfBirth,
  gender,
  languages,
  onChange,
  personId,
}) => (
  <div>
    <div className='row'>
      <InlineHeader heading='Demographic Information' />
    </div>
    <div className='row'>
      <DateField
        gridClassName='col-md-3 date-field-alignment-correction'
        id='date_of_birth'
        label='Date of birth'
        hasTime={false}
        hasCalendar={false}
        value={dateOfBirth}
        onChange={(value) => onChange('date_of_birth', value)}
      />
      <div className='col-md-1 text-between-inputs'>or</div>
      <InputField
        gridClassName='col-md-3'
        id='approximate_age'
        label='Approximate Age'
        allowCharacters={/[0-9]/}
        maxLength='3'
        value={approximateAge}
        onChange={({target: {value}}) => onChange('approximate_age', value)}
        disabled={approximateAgeIsDisabled}
      />
      <div className='col-md-2 input-no-header'>
        <select
          id='approximate_age_units'
          aria-label='Approximate Age Units'
          value={approximateAgeUnit}
          onChange={({target: {value}}) => onChange('approximate_age_units', value)}
          disabled={approximateAgeIsDisabled}
        >
          <option key='' value='' />
          {Object.keys(APPROXIMATE_AGE_UNITS).map((unit) => {
            const [first, ...rest] = unit
            const realUnit = [first.toUpperCase(), ...rest].join('')
            return (<option key={unit} value={unit}>{realUnit}</option>)
          })
          }
        </select>
      </div>
      <SelectField
        gridClassName='col-md-3'
        id='gender'
        label='Sex at Birth'
        value={gender}
        onChange={({target: {value}}) => onChange('gender', value)}
      >
        <option key='' value='' />
        {Object.keys(GENDERS).map((gender) => <option key={gender} value={gender}>{GENDERS[gender]}</option>)}
      </SelectField>
    </div>
    <div className='row'>
      <div className='col-md-12'>
        <label htmlFor={`languages_${personId}`}>Language(s) (Primary First)</label>
        <Select
          multi
          tabSelectsValue={false}
          inputProps={{id: `languages_${personId}`}}
          options={LANGUAGES.map((language) => ({value: language, label: language}))}
          value={languages}
          onChange={(languages) => onChange('languages', languages)}
        />
      </div>
    </div>
  </div>
)
PersonDemographicsForm.propTypes = {
  approximateAge: PropTypes.string,
  approximateAgeIsDisabled: PropTypes.bool,
  approximateAgeUnit: PropTypes.string,
  dateOfBirth: PropTypes.string,
  gender: PropTypes.string,
  languages: PropTypes.array,
  onChange: PropTypes.func,
  personId: PropTypes.string,
}
export default PersonDemographicsForm
