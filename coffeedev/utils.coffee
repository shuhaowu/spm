exports = namespace "utils"

delta_time = exports["delta_time"] = (delta) ->
  if delta < 0
    delta = -delta
    status = (m) -> "in #{m}"
  else
    status = (m) -> "#{m} ago"
  if delta < 60
    return status("less than a minute")
  else if delta < 120
    return status("about a minute")
  else if delta < 2700
    return status((parseInt(delta / 60)).toString() + " minutes")
  else if delta < 5400
    return status("about an hour")
  else if delta < 86400
    return status("about " + (parseInt(delta / 3600)).toString() + " hours")
  else if delta < 172800
    return status("one day")
  else
    return status((parseInt(delta / 86400)).toString() + " days")

exports["relative_time"] = (time_value) ->
  parsed_date = Date.parse(time_value)
  relative_to = if arguments.length > 1 then arguments[1] else new Date()
  delta = parseInt((relative_to.getTime() - parsed_date) / 1000)
  delta_time(delta)