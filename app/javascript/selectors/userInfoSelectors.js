import {Map, List} from 'immutable'
import {createSelector} from 'reselect'

export const getUserInfo = (state) => state.get('userInfo', Map())

export const getUserNameSelector = createSelector(
  getUserInfo,
  (userInfo) => userInfo.toJS()
)

export const getStaffIdSelector = createSelector(
  getUserInfo,
  (userInfo) => userInfo.get('staff_id')
)

export const userPrivilegesSelector = createSelector(
  getUserInfo,
  (userInfo) => userInfo.get('privileges') || List()
)
