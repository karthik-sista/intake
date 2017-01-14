import CheckboxField from 'components/common/CheckboxField'
import Immutable from 'immutable'
import RACES from 'Races'
import React from 'react'
import SelectField from 'components/common/SelectField'

export class RacesEditView extends React.Component {
  constructor() {
    super(...arguments)
  }

  changeRace(race, isChecked) {
    const {races} = this.props
    if (isChecked) {
      let newRaces
      if (RACES[race].exclusive) {
        newRaces = Immutable.fromJS([{race: race}])
      } else {
        newRaces = this.props.races.push(Immutable.Map({race: race}))
      }
      this.props.onChange(newRaces)
    } else {
      this.props.onChange(races.filterNot((item) => item.get('race') === race))
    }
  }

  changeRaceDetail(race, raceDetail) {
    const {races} = this.props
    const index = races.toJS().findIndex((item) => item.race === race)
    let newRaces
    if (raceDetail) {
      newRaces = races.set(index, {race: race, race_detail: raceDetail})
    } else {
      newRaces = races.set(index, {race: race})
    }
    this.props.onChange(newRaces)
  }

  persistedRaceInfo(race) {
    return this.props.races.toJS().find((item) => item.race === race)
  }

  raceData() {
    const persistedRaces = this.props.races.toJS()
    const exclusiveRaceSelected = persistedRaces.find(({race}) => RACES[race].exclusive)

    const raceData = Object.keys(RACES).map((race) => {
      const persistedRaceInfo = this.persistedRaceInfo(race)
      return {
        race: race,
        selected: Boolean(persistedRaceInfo),
        raceDetails: RACES[race].raceDetails,
        selectedRaceDetail: persistedRaceInfo && persistedRaceInfo.race_detail,
        disabled: exclusiveRaceSelected && !persistedRaceInfo,
      }
    })
    return raceData
  }

  render() {
    return (
      <div className='gap-top'>
        <fieldset className='fieldset-inputs sans'>
          <label>Race</label>
          <ul className='unstyled-list css-column-count--two'>
            {
              this.raceData().map((item) => {
                const {race, selected, raceDetails, selectedRaceDetail, disabled} = item
                return (
                  <li key={race}>
                    <CheckboxField
                      key={race}
                      id={race}
                      value={race}
                      checked={selected}
                      disabled={disabled}
                      onChange={(event) => this.changeRace(race, event.target.checked)}
                    />
                    {
                      selected && raceDetails &&
                        <SelectField
                          id={`${race}-race-detail`}
                          label={''}
                          value={selectedRaceDetail || ''}
                          onChange={(event) => this.changeRaceDetail(race, event.target.value)}
                        >
                          <option key='' value='' />
                          {
                            raceDetails.map((raceDetail) => (
                              <option key={raceDetail} value={raceDetail}>{raceDetail}</option>
                              ))
                          }
                        </SelectField>
                    }
                  </li>
                  )
              })
            }
          </ul>
        </fieldset>
        <hr />
      </div>
    )
  }
}

RacesEditView.propTypes = {
  onChange: React.PropTypes.func.isRequired,
  races: React.PropTypes.object.isRequired,
}

export default RacesEditView
