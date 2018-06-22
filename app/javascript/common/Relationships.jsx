import PropTypes from 'prop-types'
import React from 'react'
import ActionMenu from 'common/ActionMenu'
import AttachLink from 'common/AttachLink'
import RelationCard from 'common/RelationCard'
import ScreeningCreateRelationship from 'views/ScreeningCreateRelationship'

const actionsMenu = (row, pendingPeople, isScreening, screeningId, onClick) =>
  <ActionMenu
    relationship ={row}
    pendingPeople={pendingPeople}
    isScreening={isScreening}
    screeningId={screeningId}
    onClick={onClick}
  />

const createRelationsData = (firstName, data) => {
  const relationData = []
  data.map((rec) => relationData.push({focus_person: firstName, related_person: rec.name}))
  return relationData
}

export const Relationships = ({people, onClick, screeningId, isScreening, pendingPeople = []}) => {
  console.log(`relationshis - people ${JSON.stringify(people)}`)
  return (
  
  <div className='card-body no-pad-top'>
    {
      isScreening && people.map((person, index) => (
        <div className='row' key={`new-${index}`}>
          <div className='col-md-12'>
            {
              (person.relationships.length > 0) &&
              <span>
                <RelationCard
                  firstName={person.name}
                  lastName={person.newly_created_person}
                  data={person.relationships}
                  tableActions={(cell, row) => (actionsMenu(row, pendingPeople, isScreening, screeningId, onClick)
                  )}
                />
              </span>
            }
            {
              (person.relationships.length === 0) &&
              <div className='no-relationships well'><strong>{person.name}</strong> has no known relationships</div>
            }
            <div className='row'>
              <div className='col-md-9' />
              <div className='col-md-3'>
                <ScreeningCreateRelationship data={createRelationsData(person.name, person.relationships)}/>
              </div>
            </div>
          </div>
        </div>
      ))
    }
    {
      !isScreening && people.map((person, index) => (
        <div className='row' key={index}>
          <div className='col-md-6 gap-top'>
            <span className='person'>{person.name}</span>
            {
              (person.relationships.length > 0) &&
              <span>
                <strong> is the...</strong>
                <ul className='relationships'>
                  {
                    person.relationships.map((relationship, index) => (
                      <li key={index}>
                        <strong>{ relationship.type }</strong> &nbsp; of { relationship.name }
                        <AttachLink
                          isScreening={isScreening}
                          onClick={onClick}
                          pendingPeople={pendingPeople}
                          relationship={relationship}
                          screeningId={screeningId}
                        />
                      </li>
                    ))
                  }
                </ul>
              </span>
            }
            {
              (person.relationships.length === 0) &&
              <strong className='relationships'> has no known relationships</strong>
            }
          </div>
        </div>
      ))
    }
  </div>
)}

Relationships.propTypes = {
  isScreening: PropTypes.bool,
  onClick: PropTypes.func,
  pendingPeople: PropTypes.arrayOf(PropTypes.string),
  people: PropTypes.arrayOf(PropTypes.shape({
    name: PropTypes.string,
    relationships: PropTypes.arrayOf(PropTypes.shape({
      name: PropTypes.string,
      type: PropTypes.string,
      secondaryRelationship: PropTypes.string,
    })),
  })),
  screeningId: PropTypes.string,
}

export const EmptyRelationships = () => (
  <div className='card-body no-pad-top'>
    <div className='row'>
      <div className='col-md-12 empty-relationships'>
        <div className='double-gap-top  centered'>
          <span className='c-dark-grey'>Search for people and add them to see their relationships.</span>
        </div>
      </div>
    </div>
  </div>
)
