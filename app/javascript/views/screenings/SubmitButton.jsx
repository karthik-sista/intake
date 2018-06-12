import PropTypes from 'prop-types'

const SubmitButton = ({editable, disableSubmitButton, actions: submitScreening}) => {
  if(editable) {
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
