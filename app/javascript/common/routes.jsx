import React from 'react'
import {Router, Route, IndexRoute} from 'react-router'
import App from 'common/App'
import {default as HomePageContainer} from 'containers/HomePageContainer'
import ScreeningPage from 'containers/screenings/ScreeningContainer'
import SnapshotPage from 'snapshots/SnapshotPage'
import ConditionsOfUse from 'views/pages/ConditionsOfUse'
import PrivacyPolicy from 'views/pages/PrivacyPolicy'
import NotFoundPage from 'errors/NotFoundPage'
import ForbiddenPage from 'errors/ForbiddenPage'
import ServerErrorPage from 'errors/ServerErrorPage'
import {store} from 'store/configureStore'
import {Provider} from 'react-redux'
import {routerHistory} from 'common/history'
import {createSelectLocationState} from 'reducers/routerReducer'
import {syncHistoryWithStore} from 'react-router-redux'
import * as IntakeConfig from 'common/config'

const history = syncHistoryWithStore(routerHistory, store, {selectLocationState: createSelectLocationState()})

const snapshotActive = IntakeConfig.isFeatureActive('snapshot')
const screeningActive = IntakeConfig.isFeatureActive('screenings')

export default (
  <Provider store={store}>
    <Router history={history} >
      <Route path='/' component={App}>
        <IndexRoute component={HomePageContainer} />
        {screeningActive && <Route path='screenings/:id' component={ScreeningPage}/>}
        {screeningActive && <Route path='screenings/:id/:mode' component={ScreeningPage} />}
        {snapshotActive && <Route path='snapshot' component={SnapshotPage}/>}
        <Route path='logout' component={() => (window.location = IntakeConfig.config().authentication_logout_url)}/>
        <Route path='pages/conditions_of_use' component={ConditionsOfUse}/>
        <Route path='pages/privacy_policy' component={PrivacyPolicy}/>
        <Route path='server_error' component={ServerErrorPage}/>
        <Route path='forbidden' component={ForbiddenPage}/>
        <Route path='*' component={NotFoundPage}/>
      </Route>
    </Router>
  </Provider>
)
