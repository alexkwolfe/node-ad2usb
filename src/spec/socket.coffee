EventEmitter = require('events').EventEmitter
Duplex = require('stream').Duplex

class Socket extends Duplex
  constructor: ->
    @data = []
    @written = null
    super

  write: (msg) ->
    @written = msg
    @emit('readable') if @data.length

  read: ->
    try
      if @data.length
        "#{@data.join('\n')}\n"
      else
        null
    finally
      @data = []

  send: (data) ->
    @data.push data
    @emit('readable')

module.exports = Socket