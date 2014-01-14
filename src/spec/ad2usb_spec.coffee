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

  it 'should emit disarmed', (done) ->
    alarm.on 'disarmed', done
    socket.emit 'data', '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "\n'

  it 'should emit armed stay', (done) ->
    alarm.on 'armedStay', done
    socket.emit 'data', '[0010000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***STAY***                "\n'

  it 'should emit armed away', (done) ->
    alarm.on 'armedAway', done
    socket.emit 'data', '[0100000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***AWAY***                "\n'

  it 'should not repeatedly emit disarmed', (done)->
    count = 0
    alarm.on 'disarmed', ->
      count += 1
    socket.emit 'data', '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "\n'
    socket.emit 'data', '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "\n'
    assertion = ->
      assert.equal(1, count)
      done()
    setTimeout assertion, 10

  it 'should not repeatedly emit armed stay', (done)->
    count = 0
    alarm.on 'armedStay', ->
      count += 1
    socket.emit 'data', '[0010000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***STAY***                "\n'
    socket.emit 'data', '[0010000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***STAY***                "\n'
    assertion = ->
      assert.equal(1, count)
      done()
    setTimeout assertion, 10

  it 'should not repeatedly emit armed away', (done) ->
    count = 0
    alarm.on 'armedAway', ->
      count += 1
    socket.emit 'data', '[0100000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***AWAY***                "\n'
    socket.emit 'data', '[0100000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***AWAY***                "\n'
    assertion = ->
      assert.equal(1, count)
      done()
    setTimeout assertion, 10

  it 'should emit once when alarm status changes', (done) ->
    disarmedCount = 0
    armedCount = 0
    alarm.on 'disarmed', -> disarmedCount += 1
    alarm.on 'armedAway', -> armedCount += 1
    socket.emit 'data', '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "\n'
    socket.emit 'data', '[0100000100000000----],008,[f702000b1008008c08020000000000],"ARMED ***AWAY***                "\n'
    assertion = ->
      assert.equal 1, disarmedCount
      assert.equal 1, armedCount
      done()
    setTimeout assertion, 10

  it 'should not reset alarm status', (done) ->
    count = 0
    alarm.on 'disarmed', ->
      count += 1
    socket.emit 'data', '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "\n'
    socket.emit 'data', '[0000000100000000----],008,[f702000b1008000c08020000000000],"****DISARMED****Hit * for faults"\n'
    socket.emit 'data', '[1000000100000000----],008,[f702000b1008001c08020000000000],"****DISARMED****  Ready to Arm  "\n'
    assertion = ->
      assert.equal(1, count)
      done()
    setTimeout assertion, 10

  it 'should emit rf battery fault', (done) ->
    alarm.on 'battery:0102532', (ok) ->
      assert.ok !ok
      done()
    socket.emit 'data', '!RFX:0102532,02\n'

  it 'should emit rf supervision fault', (done) ->
    alarm.on 'supervision:0102532', (ok) ->
      assert.ok !ok
      done()
    socket.emit 'data', '!RFX:0102532,04\n'

  it 'should emit rf loop 1 fault', (done) ->
    alarm.on 'loop:0102532:1', (ok) ->
      assert.ok !ok
      done()
    socket.emit 'data', '!RFX:0102532,80\n'

  it 'should emit rf loop 2 fault', (done) ->
    alarm.on 'loop:0102532:2', (ok) ->
      assert.ok !ok
      done()
    socket.emit 'data', '!RFX:0102532,20\n'

  it 'should emit rf loop 3 fault', (done) ->
    alarm.on 'loop:0102532:3', (ok) ->
      assert.ok !ok
      done()
    socket.emit 'data', '!RFX:0102532,10\n'

  it 'should emit rf loop 4 fault', (done) ->
    alarm.on 'loop:0102532:4', (ok) ->
      assert.ok !ok
      done()
    socket.emit 'data', '!RFX:0102532,40\n'

  it 'should not crash on parse error', (done) ->
    alarm.on 'error', ->
      done()
    socket.emit 'data', '[1000000100000000----],008,[f702\n'
