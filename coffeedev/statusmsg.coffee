# statusmsg = {}
statusmsg = namespace "statusmsg"

set_human_msg_css = (msgbox) ->
  msgbox.css("position", "fixed").css("left", ($(window).width() - $(msgbox).outerWidth()) / 2)

statusmsg["setup"] = (appendTo="body", msgOpacity=0.8, msgID="statusmsg") ->
  statusmsg.msgID = msgID
  statusmsg.msgOpacity = msgOpacity

  statusmsg.msgbox = $('<div id="' + statusmsg.msgID + '" class="statusmsg"></div>')
  $(appendTo).append(statusmsg.msgbox)

  $(window).resize(() ->
    set_human_msg_css(statusmsg.msgbox)
  )
  $(window).resize()

statusmsg["display"] = (msg) ->
  statusmsg.msgbox.html(msg)
  set_human_msg_css(statusmsg.msgbox)
  statusmsg.msgbox.fadeIn()

statusmsg["close"] = () ->
  statusmsg.msgbox.fadeOut()