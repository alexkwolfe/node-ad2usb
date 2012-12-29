EventEmitter = require('events').EventEmitter

class Socket extends EventEmitter
  constructor: ->
    @response = null

  write: (data) ->
    @data = data
    @emit('data', "#{@response}\n") if @response

module.exports = Socket