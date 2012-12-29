A driver for the Nutech AD2USB Ademco Vista security system panel interface.

[![Build Status](https://secure.travis-ci.org/alexkwolfe/node-ad2usb.png)](http://travis-ci.org/alexkwolfe/node-ad2usb)

## Usage

Call the connect function to connect with the AD2USB controller. After the connection has been established,
proceed by interacting with the controller.

```javascript
var Alarm = require('ad2usb');
var alarm = Alarm.connect('192.168.1.6', 4999, function() {
  // connected to interface

  // listen for alarm to be armed
  alarm.on('armedAway', function() {
    console.log('Alarm has been armed in away mode');
  });

  // arm in away mode with user code 1234
  alarm.armAway('1234');
});
```

You may also opt to manually set up a socket and provide it to the constructor directly.

```javascript
var Alarm = require('ad2usb'),
    Socket = require('net').Socket;
var socket = new Socket({type: 'tcp4'});
var alarm = new Alarm(socket);
alarm.connect('192.168.1.6', 4999);
```