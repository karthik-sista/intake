import PropTypes from 'prop-types'
import React from 'react'
import {connect} from 'react-redux'
import {PageHeader as WoodDuckPageHeader} from 'react-wood-duck'
import PageError from 'common/PageError'
import {
  getHasGenericErrorValueSelector,
  getPageErrorMessageValueSelector,
} from 'selectors/errorsSelectors'

export class PageHeader extends React.Component {
  constructor(props) {
    super(props)
    this.handleScroll = this.handleScroll.bind(this)
  }
  componentDidMount() {
    window.addEventListener('scroll', this.handleScroll)
  }
  componentWillUnmount() {
    window.removeEventListener('scroll', this.handleScroll)
  }

  handleScroll() {
    let header
    var headerSticky = header || document.getElementById('page-stickyHeader')
    var sticky = headerSticky.offsetTop
    if (window.pageYOffset > sticky) {
      headerSticky.classList.add('sticky-pageheader')
    } else {
      headerSticky.classList.remove('sticky-pageheader')
    }
  }
  render() {
    const {button, errorMessage, hasError, pageTitle} = this.props
    return (
      <div id='page-stickyHeader'>
        <WoodDuckPageHeader pageTitle={pageTitle} button={button}>
          {hasError && <PageError pageErrorMessage={errorMessage} />}
        </WoodDuckPageHeader>
      </div>
    )
  }
}
PageHeader.propTypes = {
  button: PropTypes.object,
  errorMessage: PropTypes.string,
  hasError: PropTypes.bool,
  pageTitle: PropTypes.string,
}

const mapStateToProps = (state, ownProps) => ({
  pageTitle: ownProps.pageTitle,
  button: ownProps.button,
  hasError: getHasGenericErrorValueSelector(state),
  errorMessage: getPageErrorMessageValueSelector(state),
})

export default connect(mapStateToProps)(PageHeader)
