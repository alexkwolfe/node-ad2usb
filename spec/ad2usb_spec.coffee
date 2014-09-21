assert = require('chai').assert
Alarm = require('../src/ad2usb')
Socket = require('./socket')

describe 'AD2USB', ->
  alarm = null
  socket = null

  beforeEach ->
    socket = new Socket()
    alarm = new Alarm(socket)

  it 'should arm away', (done) ->
    socket.data.push '!Sending.done'
    alarm.armAway '1234', ->
      assert.equal socket.written, '12342'
      done()

  it 'should arm stay', (done) ->
    socket.data.push '!Sending.done'
    alarm.armStay '1234', ->
      assert.equal socket.written, '12343'
      done()

  it 'should disarm', (done) ->
    socket.data.push '!Sending.done'
    alarm.disarm '1234', ->
      assert.equal socket.written, '12341'
      done()

  it 'should bypass', (done) ->
    socket.data.push '!Sending.done'
    alarm.bypass '1234', '12', ->
      assert.equal socket.written, '1234612'
      done()

  it 'should emit disarmed', (done) ->
    alarm.on 'disarmed', done
    socket.send '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "'

  it 'should emit armed stay', (done) ->
    alarm.on 'armedStay', done
    socket.send '[0010000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***STAY***                "'

  it 'should emit armed away', (done) ->
    alarm.on 'armedAway', done
    socket.send '[0100000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***AWAY***                "'

  it 'should not repeatedly emit disarmed', (done)->
    count = 0
    alarm.on 'disarmed', ->
      count += 1
    socket.send '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "'
    socket.send '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "'
    assertion = ->
      assert.equal(1, count)
      done()
    setTimeout assertion, 10

  it 'should not repeatedly emit armed stay', (done)->
    count = 0
    alarm.on 'armedStay', ->
      count += 1
    socket.send '[0010000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***STAY***                "'
    socket.send '[0010000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***STAY***                "'
    assertion = ->
      assert.equal(1, count)
      done()
    setTimeout assertion, 10

  it 'should not repeatedly emit armed away', (done) ->
    count = 0
    alarm.on 'armedAway', ->
      count += 1
    socket.send '[0100000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***AWAY***                "'
    socket.send '[0100000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***AWAY***                "'
    assertion = ->
      assert.equal(1, count)
      done()
    setTimeout assertion, 10

  it 'should emit once when alarm status changes', (done) ->
    disarmedCount = 0
    armedCount = 0
    alarm.on 'disarmed', -> disarmedCount += 1
    alarm.on 'armedAway', -> armedCount += 1
    socket.send '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "'
    socket.send '[0100000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***AWAY***                "'
    assertion = ->
      assert.equal 1, disarmedCount, "disarmed event occurred #{disarmedCount} times"
      assert.equal 1, armedCount, "armed event occurred #{armedCount} times"
      done()
    setTimeout assertion, 10

  it 'should not reset alarm status', (done) ->
    count = 0
    alarm.on 'disarmed', ->
      count += 1
    socket.send '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "'
    socket.send '[0000000100000000----],008,[f702000b1008000c08020000000000],"****DISARMED****Hit * for faults"'
    socket.send '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "'
    assertion = ->
      assert.equal(1, count)
      done()
    setTimeout assertion, 10

  it 'should emit rf battery fault', (done) ->
    alarm.on 'battery:0102532', (ok) ->
      assert.ok !ok
      done()
    socket.send '!RFX:0102532,02\n'

  it 'should emit rf supervision fault', (done) ->
    alarm.on 'supervision:0102532', (ok) ->
      assert.ok !ok
      done()
    socket.send '!RFX:0102532,04\n'

  it 'should emit rf loop 1 fault', (done) ->
    alarm.on 'loop:0102532:1', (ok) ->
      assert.ok !ok
      done()
    socket.send '!RFX:0102532,80\n'

  it 'should emit rf loop 2 fault', (done) ->
    alarm.on 'loop:0102532:2', (ok) ->
      assert.ok !ok
      done()
    socket.send '!RFX:0102532,20\n'

  it 'should emit rf loop 3 fault', (done) ->
    alarm.on 'loop:0102532:3', (ok) ->
      assert.ok !ok
      done()
    socket.send '!RFX:0102532,10\n'

  it 'should emit rf loop 4 fault', (done) ->
    alarm.on 'loop:0102532:4', (ok) ->
      assert.ok !ok
      done()
    socket.send '!RFX:0102532,40\n'

  it 'should not crash on parse error', (done) ->
    alarm.on 'error', ->
      done()
    socket.send '[1000000100000000----],008,[f702\n'
