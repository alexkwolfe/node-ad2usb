BufferStream = require('bufferstream')
EventEmitter = require('events').EventEmitter
Socket = require('net').Socket


class Alarm extends EventEmitter
  constructor: (@socket) ->
    @buffer = new BufferStream(encoding: 'utf8', size: 'flexible')
    @buffer.split '\n', (message) =>
      @handleMessage(message.toString('ascii'))
    @socket.on('data', @handleData)

  ###
  Internal: Handle a chunk of data sent by the AD2SUB interface by writing it to the buffer.
  ###
  handleData: (data) =>
    @buffer.write(data.toString('ascii'))

  ###
  Internal: A message has been received and must be handled.
  msg: String message sent by the AD2USB interface.
  ###
  panelMessageRegex = /^\[/
  rfMessageRegex = /^!RFX/
  sendingRegex = /^!Sending(\.*)done/
  handleMessage: (msg) ->
    if msg.match(panelMessageRegex)
      @handlePanelData msg
    else if msg.match(rfMessageRegex)
      @handleRfMessage msg
    else if msg.match(sendingRegex)
      @emit 'sent'


  ###
  Internal: Panel data has been received. Parse it, keep state, and emit events when state changes.
  ###
  handlePanelData: (msg) ->
    parts = msg.split(',')

    # Section 1:  [1000000100000000----]
    sec1 = parts[0].replace(/[\[\]]/g, '').split('')
    @state 'disarmed', sec1.shift() == '1'
    @state 'armedAway', sec1.shift() == '1'
    @state 'armedStay', sec1.shift() == '1'
    @state 'backlight', sec1.shift() == '1'
    @state 'programming', sec1.shift() == '1'

    beeps = parseInt(sec1.shift(), 10)
    @emit 'beeps', beeps if beeps > 0

    @state 'bypass', sec1.shift() == '1'
    @state 'power', sec1.shift() == '1'
    @state 'chimeMode', sec1.shift() == '1'
    @state 'alarmOccured', sec1.shift() == '1'
    @state 'alarm', sec1.shift() == '1'
    @state 'batteryLow', sec1.shift() == '1'
    @state 'entryDelayOff', sec1.shift() == '1'
    @state 'fireAlarm', sec1.shift() == '1'
    @state 'checkZone', sec1.shift() == '1'
    @state 'perimeterOnly', sec1.shift() == '1'

    # Section 2: 008
    sec2 = parts[1]
    @faultedZone = sec2 # What should be done with this?

    # Section 3: [f702000b1008001c08020000000000]
    sec3 = parts[3].replace(/[\[\]]/g, '')
    @raw = sec3 # What should be done with this?


  ###
  Internal: A RF sensor has reported its status. Parse it, keep state and emit events when state changes.
  ###
  handleRfMessage: (msg) ->
    parts = msg.replace('!RFX:', '').split(',')
    serial = parts.shift()
    status = parseInt(parts.shift(), 16).toString(2).split('')
    status =
      battery: status[1] == '1'
      supervision: status[2] == '1'
      loop1: status[7] == '1'
      loop2: status[5] == '1'
      loop3: status[4] == '1'
      loop4: status[6] == '1'
    state "zone:#{serial}", status.supervision
    state "battery:#{serial}", status.battery
    state "loop:#{serial}", [status.loop1, status.loop2, status.loop3, status.loop4]

    
  ###
  ###
  state: (name, state) ->
    changed =  @[name] != state
    if changed
      @[name] = state
      @emit name, state
    changed
    
      
  ###
  Internal: Send a command to the AD2USB interface.

  code: String command to send (i.e. "12341")
  callback: function invoked when interface acknowledges command (optional)

  Returns true if command is sent, otherwise false.
  ###
  send: (cmd, callback) ->
    @once 'sent', (msg) -> callback(null, msg) if callback
    @socket.write(cmd)


  armAway: (code, callback) ->
    @send "#{code}2", callback

  armStay: (code, callback) ->
    @send "#{code}3", callback

  disarm: (code, callback) ->
    @send "#{code}1", callback

  bypass: (code, zone, callback) ->
    @send "#{code}5#{zone}", callback

  ###
  Public: Connect to the AD2USB device using a TCP socket.

  ip: String IP address of interface
  port: Integer TCP port of interface (optional, defaults to 4999)
  callback: invoked once the connection has been established (optional)
  ###
  @connect: (args...) ->
    callback = args.pop() if typeof args[args.length - 1] == 'function'
    ip = args.shift()
    port = args.shift() ? 10001

    socket = new Socket(type: 'tcp4')
    alarm = new Alarm(socket)
    socket.connect(port, ip, callback)
    alarm


module.exports = Alarm

