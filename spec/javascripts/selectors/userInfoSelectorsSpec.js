import {fromJS, List} from 'immutable'
import {
  getUserNameSelector,
  userPrivilegesSelector,
  getStaffIdSelector,
} from 'selectors/userInfoSelectors'
import * as matchers from 'jasmine-immutable-matchers'

describe('userInfoSelectors', () => {
  beforeEach(() => jasmine.addMatchers(matchers))

  describe('getFullNameSelector', () => {
    it('returns the js object payload ', () => {
      const userInfo = {first_name: 'Henry', last_name: 'Ford'}
      const state = fromJS({userInfo})
      expect(getUserNameSelector(state)).toEqual({first_name: 'Henry', last_name: 'Ford'})
    })

    it('returns empty on an empty payload', () => {
      const userInfo = {}
      const state = fromJS({userInfo})
      expect(getUserNameSelector(state)).toEqual({})
    })
  })

  describe('getStaffIdSelector', () => {
    it('returns the staff id from users info', () => {
      const userInfo = {staff_id: '0x4'}
      const state = fromJS({userInfo})
      expect(getStaffIdSelector(state)).toEqual('0x4')
    })
  })

  describe('userPrivilegesSelector', () => {
    it('returns the list of privileges', () => {
      const userInfo = {privileges: ['one', 'two']}
      const state = fromJS({userInfo})
      expect(userPrivilegesSelector(state)).toEqual(List(['one', 'two']))
    })
    it('returns an empty list when there are no privileges', () => {
      const state = fromJS({userInfo: {}})
      expect(userPrivilegesSelector(state)).toEqual(List())
    })
  })
})
