"use strict"

orm = require("orm")
redis = require("redis")
config = require("../config")

db = zk = redis_client = redis_publish = null
cbs = []

redis_url = require("url").parse config.redis_url
redis_hostname = redis_url.hostname
redis_port = redis_url.port or 6379

require("./db") config.mysql_url, (err, conn) ->
  throw new Error("DB connection exception due to #{err}") if err?

  db = conn
  redis_client = redis.createClient(redis_port, redis_hostname)
  redis_subscribe = redis.createClient(redis_port, redis_hostname)
  zk = require("./zk") config.zk_url, config.zk_path, db.models, redis_client, redis_subscribe
  cb() for cb in cbs

exports = module.exports =
  setup: ->
    (req, res, next) ->
      req.db = db
      req.redis = redis_client
      req.zk = zk
      next()
  initialize: (cb) ->
    if db? and zk?
      cb()
    else
      cbs.push cb  
  db: -> db
  zk: -> zk
  redis: -> redis.createClient(redis_port, redis_hostname)
