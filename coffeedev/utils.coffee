exports = namespace "utils"

exports["relative_time"] = (time_value) ->
  parsed_date = Date.parse(time_value)
  relative_to = if arguments.length > 1 then arguments[1] else new Date()
  delta = parseInt((relative_to.getTime() - parsed_date) / 1000)
  if delta < 60
    return "less than a minute ago"
  else if delta < 120
    return "about a minute ago"
  else if delta < 2700
    return (parseInt(delta / 60)).toString() + " minutes ago"
  else if delta < 5400
    return "about an hour ago"
  else if delta < 86400
    return "about " + (parseInt(delta / 3600)).toString() + " hours ago"
  else if delta < 172800
    return "one day ago"
  else
    return (parseInt(delta / 86400)).toString() + " days ago"