assert = require('chai').assert
Alarm = require('../ad2usb')
Socket = require('./socket')

describe 'Callback', ->
  alarm = null
  socket = null

  beforeEach ->
    socket = new Socket()
    alarm = new Alarm(socket)

  it 'should callback on sent response', (done) ->
    socket.response = '!Sending..done'
    alarm.send '12341', -> done()

