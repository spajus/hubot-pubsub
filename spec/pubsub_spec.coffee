path = require 'path'
Robot = require 'hubot/src/robot'
messages = require 'hubot/src/message'

describe 'pubsub', ->

  robot = null
  adapter = null
  user = null

  say = (msg) ->
    adapter.receive new messages.TextMessage(user, msg)

  expectHubotToSay = (msg, done) ->
    adapter.on 'send', (envelope, strings) ->
      (expect strings[0]).toMatch msg
      done()

  captureHubotOutput = (captured, done) ->
    adapter.on 'send', (envelope, strings) ->
      unless strings[0] in captured
        captured.push strings[0]
        done()

  beforeEach ->
    ready = false

    runs ->
      robot = new Robot(null, 'mock-adapter', false, 'Hubot')

      robot.adapter.on 'connected', ->
        process.env.HUBOT_AUTH_ADMIN = '1'

        (require '../src/pubsub')(robot)

        user = robot.brain.userForId('1', name: 'jasmine', room: '#jasmine')
        adapter = robot.adapter
        ready = true

      robot.run()

    waitsFor -> ready

  afterEach ->
    robot.shutdown()

  it 'lists current room subscriptions when none are present', (done) ->
    expectHubotToSay 'Total subscriptions for #jasmine: 0', done
    say 'hubot subscriptions'

  it 'lists current room subscriptions', (done) ->
    robot.brain.data.subscriptions =
      'foo.bar': [ '#jasmine', '#other' ]
      'baz': [ '#foo', '#jasmine' ]

    count = 0
    captured = []

    doneLatch = ->
      count += 1
      if count == 3
        (expect 'foo.bar -> #jasmine' in captured).toBeTruthy()
        (expect 'baz -> #jasmine' in captured).toBeTruthy()
        (expect 'Total subscriptions for #jasmine: 2' in captured).toBeTruthy()
        done()

    captureHubotOutput captured, doneLatch
    captureHubotOutput captured, doneLatch
    captureHubotOutput captured, doneLatch

    say 'hubot subscriptions'

  it 'lists all subscriptions', (done) ->
    expectHubotToSay 'Total subscriptions: 0', done
    say 'hubot all subscriptions'

  it 'subscribes a room', (done) ->
    expectHubotToSay 'Subscribed #jasmine to foo.bar_baz events', ->
      (expect robot.brain.data.subscriptions['foo.bar_baz']).toEqual [ '#jasmine' ]
      done()

    say 'hubot subscribe foo.bar_baz'

  it 'cannot unsubscribe a room which was not subscribed', (done) ->
    expectHubotToSay '#jasmine was not subscribed to foo.bar_baz events', done
    say 'hubot unsubscribe foo.bar_baz'

  it 'unsubscribes a room', (done) ->
    robot.brain.data.subscriptions = 'foo.bar_baz': [ '#jasmine' ]

    expectHubotToSay 'Unsubscribed #jasmine from foo.bar_baz events', ->
      (expect robot.brain.data.subscriptions['foo.bar_baz']).toEqual [ ]
      done()

    say 'hubot unsubscribe foo.bar_baz'

  it 'allows subscribing all unsubscribed events for debugging', (done) ->
    robot.brain.data.subscriptions = 'unsubscribed.event': [ '#jasmine' ]

    count = 0
    captured = []

    doneLatch = ->
      count += 1
      if count == 2
        (expect 'unsubscribed.event: unrouted: no one should receive it' in captured).toBeTruthy()
        (expect 'Notified 0 rooms about unrouted' in captured).toBeTruthy()
        done()

    captureHubotOutput captured, doneLatch

    say 'hubot publish unrouted no one should receive it'

  it 'allows subscribing to namespaces', (done) ->
    robot.brain.data.subscriptions = 'errors.critical': [ '#jasmine' ]

    count = 0
    captured = []

    doneLatch = ->
      (expect 'errors.critical.subsystem: blew up!' in captured).toBeTruthy()
      done()

    captureHubotOutput captured, doneLatch

    say 'hubot publish errors.critical.subsystem blew up!'

  it 'handles pubsub:publish event', (done) ->
    robot.brain.data.subscriptions = 'alien.event': [ '#jasmine' ]

    count = 0
    captured = []

    doneLatch = ->
      (expect 'alien.event: hi from other script' in captured).toBeTruthy()
      done()

    captureHubotOutput captured, doneLatch

    robot.emit 'pubsub:publish', 'alien.event', 'hi from other script'
