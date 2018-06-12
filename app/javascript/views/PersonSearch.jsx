import PropTypes from 'prop-types'
import PersonSearchFormContainer from 'containers/common/PersonSearchFormContainer'
import React from 'react'

const PersonSearchCard = ({}) => (
  <PersonSearchFormContainer
    onSelect={(person) => this.onSelectPerson(person)}
    searchPrompt='Search for any person (Children, parents, collaterals, reporters, alleged perpetrators...)'
    canCreateNewPerson={true}
  />
)

export default PersonSearchCard
