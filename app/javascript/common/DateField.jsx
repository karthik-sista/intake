import DateTimePicker from 'react-widgets/lib/DateTimePicker'
import FormField from 'common/FormField'
import PropTypes from 'prop-types'
import React from 'react'
import _ from 'lodash'
import moment from 'moment-timezone'
import momentLocalizer from 'react-widgets/lib/localizers/moment'

momentLocalizer(moment)

const dateFormats = [
  'M/D/YY',
  'MM/D/YY',
  'M/DD/YY',
  'MM/DD/YYYY',
  'M-D-YY',
  'MM-D-YY',
  'M-DD-YY',
  'MM-DD-YY',
  'M-DD-YYYY',
  'M-D YY',
  'MMDDYY',
]

const dateTimeFormats = [
  'M-DD-YY h:mm A',
  'M-D-YY h:mm A',
  'MM-DD-YY h:mm A',
  'M-D-YYYY hh:mm A',
  'M/DD/YY h:mm A',
  'MM/DD/YY h:mm A',
  'M/DD/YYYY hh:mm A',
  'M-D-YY h A',
  'M-D-YY hmm',
  'M-D-YY h',
  'MMDDYYYYhmm',
  'MMDDYYYYhp',
  'M-D YY h',
  'YYYY-MM-DDTh:mm:ss.fffZ',
]

const parseDate = (date) => (
  moment.tz(date, [...dateFormats, ...dateTimeFormats], 'America/Los_Angeles').local()
)

const proxyOnChange = (onChange, hasTime) => ((date) => {
  if (date === null) {
    onChange(null)
    return
  }
  const parsedDate = parseDate(date)
  const dateOrDatetime = hasTime ? parsedDate.toISOString() : parsedDate.format('YYYY-MM-DD')
  onChange(dateOrDatetime)
})

const proxyOnBlur = (onBlur) => ((event) => {
  if (!onBlur) { return }

  const date = event.target.value
  if (_.isEmpty(date)) {
    onBlur(null)
    return
  }
  onBlur(parseDate(date).toISOString())
})

const DateField = ({
  errors,
  gridClassName,
  hasCalendar,
  hasTime,
  id,
  label,
  labelClassName,
  max,
  min,
  onBlur,
  onChange,
  required,
  value,
}) => {
  const dateValue = _.isEmpty(value) ? null : parseDate(value).toDate()
  const format = hasTime ? 'MM/DD/YYYY h:mm A' : 'MM/DD/YYYY'
  const placeholder = hasTime ? 'MM/DD/YYYY HH:MM AM/PM' : 'MM/DD/YYYY'

  return (
    <FormField htmlFor={`${id}_input`} label={label} gridClassName={gridClassName} labelClassName={labelClassName}
      required={required} errors={errors}
    >
      <DateTimePicker
        aria-required={required}
        calendar={hasCalendar}
        value={dateValue}
        format={format}
        id={id}
        onBlur={proxyOnBlur(onBlur)}
        onChange={proxyOnChange(onChange, hasTime)}
        placeholder={placeholder}
        required={required}
        time={hasTime}
        max={max}
        min={min}
      />
    </FormField>
  )
}

DateField.defaultProps = {
  hasTime: true,
  hasCalendar: true,
}

DateField.propTypes = {
  errors: PropTypes.array,
  gridClassName: PropTypes.string,
  hasCalendar: PropTypes.bool,
  hasTime: PropTypes.bool,
  id: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  labelClassName: PropTypes.string,
  max: PropTypes.instanceOf(Date),
  min: PropTypes.instanceOf(Date),
  onBlur: PropTypes.func,
  onChange: PropTypes.func.isRequired,
  required: PropTypes.bool,
  value: PropTypes.string,
}
export default DateField
