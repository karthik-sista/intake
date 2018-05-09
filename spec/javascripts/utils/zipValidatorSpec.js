import {getZIPErrors} from 'utils/zipValidator'

describe('zipValidator', () => {
  describe('getZipErrors', () => {
    it('must be 5 digits long', () => {
      expect(getZIPErrors('1234'))
        .toEqual(['zip code should be 5 digits'])
    })
    it('zip cannot start with 0', () => {
      expect(getZIPErrors('0123'))
        .toEqual(['zip code should be 5 digits'])
    })
  })
})

