import {combineCompact} from 'utils/validator'

const VALID_ZIP_LENGTH = 5

const validateZIPLength = (zip) => (
  zip.length > VALID_ZIP_LENGTH || zip.length < VALID_ZIP_LENGTH ?
    'zip code should be 5 digits' : undefined
)

export const getZIPErrors = (zip) => combineCompact(
  () => validateZIPLength(zip)
)
