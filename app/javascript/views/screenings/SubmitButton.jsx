import PropTypes from 'prop-types'
import React from 'react'

const SubmitButton = ({editable, disableSubmitButton, actions: submitScreening}) => {
  if (editable) {
    return (
      <button type='button'
        className='btn primary-btn pull-right'
        disabled={disableSubmitButton}
        onClick={() => submitScreening(id)}
      >
        Submit
      </button>
    )
  }
  return (<div />)
}

export default SubmitButton
