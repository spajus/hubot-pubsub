# Description:
#   Pub-Sub notification system for Hubot.
#   Subscribe rooms to various event notifications and publish them
#   via HTTP requests or chat messages.
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_SUBSCRIPTIONS_PASSWORD (optional)
#   HUBOT_PUBSUB_SEND_EVENT_NAME (optional, defaults true)
#
# Commands:
#   hubot subscribe <event> - subscribes current room to event. To debug, subscribe to 'unsubscribed.event'
#   hubot unsubscribe <event> - unsubscribes current room from event
#   hubot unsubscribe all events - unsubscribes current room from all events
#   hubot subscriptions - show subscriptions of current room
#   hubot all subscriptions - show all existing subscriptions
#   hubot publish <event> <data> - triggers event
#
# URLS:
#   GET /publish?event=<event>&data=<text>[&password=<password>]
#   POST /publish (Content-Type: application/json, {"password": "optional", "event": "event", "data": "text" })
#
# Events:
#   pubsub:publish <event> <data> - publishes an event from another script
#
# Author:
#   spajus


Options =
  sendEventName: process.env.HUBOT_PUBSUB_SEND_EVENT_NAME == "true" or not process.env.HUBOT_PUBSUB_SEND_EVENT_NAME?
  dataAsJSon:    process.env.HUBOT_PUBSUB_DATA_AS_JSON    == "true" or     process.env.HUBOT_PUBSUB_DATA_AS_JSON?

module.exports = (robot) ->

  url = require('url')
  querystring = require('querystring')

  subscriptions = (ev, partial = false) ->
    subs = robot.brain.data.subscriptions ||= {}
    if ev
      if '.' in ev and partial
        matched = []
        ev_parts = ev.split('.')
        while ev_parts.length > 0
          sub_ev = ev_parts.join('.')
          if subs[sub_ev]
            for e in subs[sub_ev]
              matched.push e unless e in matched
          ev_parts.pop()
        matched
      else
        subs[ev] ||= []
    else
      subs

  messageFormatter = (event, data) ->
    if Options.dataAsJSon
      message = JSON.parse(data)
    else
      message = if Options.sendEventName then "#{event}: #{data}" else "#{data}"

  notify = (event, data) ->
    count = 0
    subs = subscriptions(event, true)
    if event && subs
      for room in subs
        count += 1
        user = {}
        user.room = room
        message = messageFormatter(event, data)
        robot.send user, message
    unless count > 0
      console.log "hubot-pubsub: unsubscribed.event: #{event}: #{data}"
      for room in subscriptions('unsubscribed.event')
        user = {}
        user.room = room
        robot.send user, "unsubscribed.event: #{event}: #{data}"
    count

  persist = (subscriptions) ->
    robot.brain.data.subscriptions = subscriptions
    robot.brain.save()

  getRoomName = (robot, res) ->
    robot.adapter.client.rtm.dataStore.getChannelGroupOrDMById(res.message.room).name

  robot.respond /subscribe ([a-z0-9\-\.\:_]+)$/i, (msg) ->
    ev = msg.match[1]
    room = msg.message.user.reply_to || msg.message.user.room
    subscriptions(ev).push room
    persist subscriptions()
    msg.send "Subscribed \##{getRoomName(robot, msg)} to #{ev} events"

  robot.respond /unsubscribe ([a-z0-9\-\.\:_]+)$/i, (msg) ->
    ev = msg.match[1]
    subs = subscriptions()
    subs[ev] ||= []
    room = msg.message.user.reply_to || msg.message.user.room
    if room in subs[ev]
      index = subs[ev].indexOf room
      subs[ev].splice(index, 1)
      persist subs
      msg.send "Unsubscribed \##{getRoomName(robot, msg)} from #{ev} events"
    else
      msg.send "#{room} was not subscribed to #{ev} events"

  robot.respond /unsubscribe all events$/i, (msg) ->
    count = 0
    subs = subscriptions()
    room = msg.message.user.reply_to || msg.message.user.room
    for ev of subs
      if room in subs[ev]
        index = subs[ev].indexOf room
        subs[ev].splice(index, 1)
        count += 1
    persist subs
    msg.send "Unsubscribed \##{getRoomName(robot, msg)} from #{count} events"

  robot.respond /subscriptions$/i, (msg) ->
    count = 0
    room = msg.message.user.reply_to || msg.message.user.room
    for ev of subscriptions()
      if room in subscriptions(ev)
        count += 1
        msg.send "#{ev} -> #{room}"
    msg.send "Total subscriptions for \##{getRoomName(robot, msg)}: #{count}"

  robot.respond /all subscriptions$/i, (msg) ->
    count = 0
    for ev of subscriptions()
      for room in subscriptions(ev)
        count += 1
        msg.send "#{ev} -> #{room}"
    msg.send "Total subscriptions: #{count}"

  robot.respond /publish ([a-z0-9\-\.\:_]+) (.*)$/i, (msg) ->
    ev = msg.match[1]
    data = msg.match[2]
    count = notify(ev, data)
    msg.send "Notified #{count} rooms about #{ev}"

  robot.router.get "/publish", (req, res) ->
    query = querystring.parse(url.parse(req.url).query)
    res.end('')
    return unless query.password == process.env.HUBOT_SUBSCRIPTIONS_PASSWORD
    notify(query.event, query.data)

  robot.router.post "/publish", (req, res) ->
    res.end('')
    data = req.body
    return unless data.password == process.env.HUBOT_SUBSCRIPTIONS_PASSWORD
    notify(data.event, data.data)

  robot.on "pubsub:publish", (event, data) ->
    unless event or data
      console.log "Received incomplete pubsub:publish event. Event type: #{event}, data: #{data}"
    notify(event, data)
