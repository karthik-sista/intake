import React from 'react'
import PropTypes from 'prop-types'
import CreateUnknownPerson from 'screenings/CreateUnknownPerson'
import ShowMoreResults from 'common/ShowMoreResults'

const AutocompleterFooter = ({canCreateNewPerson, canLoadMoreResults, onLoadMoreResults, onCreateNewPerson}) => (
  <div>
    { canLoadMoreResults && <ShowMoreResults onSelect={onLoadMoreResults}/> }
    { canCreateNewPerson && <CreateUnknownPerson saveCallback={onCreateNewPerson} /> }
  </div>
)

AutocompleterFooter.propTypes = {
  canCreateNewPerson: PropTypes.bool,
  canLoadMoreResults: PropTypes.bool,
  onCreateNewPerson: PropTypes.func,
  onLoadMoreResults: PropTypes.func,
}

export default AutocompleterFooter
