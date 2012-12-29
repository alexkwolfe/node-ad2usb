assert = require('chai').assert
Alarm = require('../ad2usb')
Socket = require('./socket')

describe 'AD2USB', ->
  alarm = null
  socket = null

  beforeEach ->
    socket = new Socket()
    alarm = new Alarm(socket)

  it 'should arm away', (done) ->
    socket.response = '!Sending.done'
    alarm.armAway '1234', ->
      assert.equal socket.data, '12342'
      done()

  it 'should arm stay', (done) ->
    socket.response = '!Sending.done'
    alarm.armStay '1234', ->
      assert.equal socket.data, '12343'
      done()

  it 'should disarm', (done) ->
    socket.response = '!Sending.done'
    alarm.disarm '1234', ->
      assert.equal socket.data, '12341'
      done()

  it 'should bypass', (done) ->
    socket.response = '!Sending.done'
    alarm.bypass '1234', '12', ->
      assert.equal socket.data, '1234612'
      done()

  it 'should parse disarmed', (done) ->
    alarm.on 'disarmed', -> done()
    socket.emit 'data', '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "\n'

  it 'should parse armed stay', (done) ->
    alarm.on 'armedStay', -> done()
    socket.emit 'data', '[0010000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***STAY***                "\n'

  it 'should parse armed away', (done) ->
    alarm.on 'armedAway', -> done()
    socket.emit 'data', '[0100000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***AWAY***                "\n'

  it 'should not repeat disarmed', ->
    count = 0
    alarm.on 'disarmed', ->
      count += 1
    socket.emit 'data', '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "\n'
    socket.emit 'data', '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "\n'
    assert.equal(1, count)

  it 'should not repeat armed stay', ->
    count = 0
    alarm.on 'armedStay', ->
      count += 1
    socket.emit 'data', '[0010000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***STAY***                "\n'
    socket.emit 'data', '[0010000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***STAY***                "\n'
    assert.equal(1, count)

  it 'should not repeat armed away', ->
    count = 0
    alarm.on 'armedAway', ->
      count += 1
    socket.emit 'data', '[0100000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***AWAY***                "\n'
    socket.emit 'data', '[0100000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***AWAY***                "\n'
    assert.equal(1, count)