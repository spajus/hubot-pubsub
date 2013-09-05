hubot-pubsub
============

PubSub notification system for [Hubot](https://github.com/github/hubot)

[![Build Status](https://travis-ci.org/spajus/hubot-pubsub.png?branch=master)](https://travis-ci.org/spajus/hubot-pubsub)

![hubot-pubsub demo](https://dl.dropboxusercontent.com/u/176100/opensource/hubot-pubsub.gif)

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
  

### Issues

- HTTP password based security is weak - don't use it in public network to publish events with sensitive data
