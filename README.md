hubot-pubsub
============

PubSub notification system for [Hubot](https://github.com/github/hubot)

[![Build Status](https://travis-ci.org/spajus/hubot-pubsub.png?branch=master)](https://travis-ci.org/spajus/hubot-pubsub)

![hubot-pubsub demo](https://dl.dropboxusercontent.com/u/176100/opensource/hubot-pubsub.gif)

## Book: Automation and Monitoring with Hubot

[Automation and Monitoring with Hubot](https://leanpub.com/automation-and-monitoring-with-hubot) will show you how to build advanced monitoring systems with Hubot PubSub.

## Possibilities

`hubot-pubsub` allows you to build a simple, yet powerful monitoring / notification system using your corporate chat
(Campfire, HipChat, IRC, Jabber / XMPP or even Skype). Simply subscribe events in appropriate chat rooms and publish
info about these events via HTTP calls or from other Hubot scripts when they happen.


```
             Hubot PubSub Event Flow

+--------------+ +--------------+ +---------------+
| hubot script | | HTTP Request | | chat message  |<--+
+-------+------+ +-------+------+ +-------+-------+   |
        |                |                |           |
        |                v                |           |
        |        +--------------+         |           |
        +------->| hubot-pubsub |<--------+           |
                 +-------+------+                     |
                         |                            |
                         v                            |
                 +--------------+                     |
             +---+     hubot    +---+                 |
             |   +--------------+   |                 |
             |                      |                 |
             v                      v                 |
       +---------------+  +---------------+           |
       |  chatroom #1  |  |  chatroom #2  +-----------+
       +---------------+  +---------------+
````

## Installing

Add dependency to `package.json`:

```console
$ npm install --save hubot-pubsub
```

Include package in Hubot's `external-scripts.json`:

```json
["hubot-pubsub"]
```

## Configuration

    HUBOT_SUBSCRIPTIONS_PASSWORD   # Optional password for protecting HTTP API calls

## Commands

    hubot subscribe <event>        # subscribes current room to event
    hubot unsubscribe <event>      # unsubscribes current room from event
    hubot unsubscribe all events   # unsubscribes current room from all events
    hubot subscriptions            # show subscriptions of current room
    hubot all subscriptions        # show all existing subscriptions
    hubot publish <event> <data>   # triggers event

## HTTP API

### GET /publish

    GET /publish?event=<event>&data=<text>[&password=<password>]


### POST /publish

    POST /publish

  - Content-Type: `application/json`
  - Body: `{ "password": "optional", "event": "event", "data": "text" }`

### Event Namespaces

Hubot PubSub uses `.` as event namespace separator. I.e.: subscribing to `x.y` also subscribes to `x.y.*` events.

### Publishing events from other scripts

Emit `pubsub:publish` event from any other Hubot script to publish something via hubot-pubsub:

    robot.emit 'pubsub:publish', 'news', 'Publishing some news from another script'

### Handling unsubscribed events

Do `hubot subscribe unsubscribed.event` in a room where you want all unrouted events to get announced.

### Issues

- HTTP password based security is weak - don't use it in public network to publish events with sensitive data
