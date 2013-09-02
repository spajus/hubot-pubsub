path = require 'path'
Robot = require 'hubot/src/robot'
messages = require 'hubot/src/message'

describe 'pubsub', ->

  robot = null
  adapter = null
  user = null

  beforeEach ->
    ready = false

    runs ->
      robot = new Robot(null, 'mock-adapter', false, 'Hubot')

      robot.adapter.on 'connected', ->
        process.env.HUBOT_AUTH_ADMIN = '1'
        robot.loadFile (path.resolve path.join 'node_modules/hubot/src/scripts'), 'auth.coffee'

        (require '../lib/pubsub')(robot)

        user = robot.brain.userForId('1', name: 'jasmine', room: '#jasmine')
        adapter = robot.adapter
        ready = true

      robot.run()

    waitsFor -> ready

  afterEach ->
    robot.shutdown()

  it 'lists all subscriptions', (done) ->
    adapter.on 'send', (envelope, strings) ->
      (expect strings[0]).toMatch 'Total subscriptions: 0'
      done()

    adapter.receive new messages.TextMessage(user, 'hubot all subscriptions')
