import React from 'react'
import {SideBar, NavLinks, NavLink} from 'react-wood-duck'
import PropTypes from 'prop-types'

import nameFormatter from 'utils/nameFormatter'

const ScreeningSideBar = (props) => (
  <div className='col-xs-4 col-md-3 hide-mobile hidden-print pad-top'>
    <SideBar>
      <NavLinks>
        <NavLink text='Screening Information' href='#screening-information-card-anchor' />
        <NavLink key={1} text='People & Roles' href='#search-card-anchor'>
          <NavLinks nested={true} >
            <div className='nested-block'>
              {props.participants.map(({id, first_name, last_name, name_suffix}) =>
                <NavLink
                  key={id}
                  text={nameFormatter({first_name, last_name, name_suffix})}
                  href={`#participants-card-${id}`}
                  preIcon='fa fa-user'
                />
              )}
            </div>
          </NavLinks>
        </NavLink>
        <NavLink text='Narrative' href='#narrative-card-anchor' />
        <NavLink text='Incident Information' href='#incident-information-card-anchor' />
        <NavLink text='Allegations' href='#allegations-card-anchor' />
        <NavLink text='Relationships' href='#relationships-card-anchor' />
        <NavLink text='Worker Safety' href='#worker-safety-card-anchor' />
        <NavLink text='History' href='#history-card-anchor' />
        <NavLink text='Cross Report' href='#cross-report-card-anchor' />
        <NavLink text='Decision' href='#decision-card-anchor' />
      </NavLinks>
    </SideBar>
  </div>
)

ScreeningSideBar.propTypes = {
  participants: PropTypes.array.isRequired,
}

ScreeningSideBar.defaultProps = {
  participants: [],
}

export default ScreeningSideBar
