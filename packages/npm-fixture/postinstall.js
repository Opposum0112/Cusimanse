const fs = require('fs');
const net = require('net');

fs.writeFileSync('/tmp/cusimanse-npm-lifecycle-marker', 'postinstall-ran\n');
const socket = net.createConnection({host: '127.0.0.1', port: 20128});
socket.setTimeout(500);
socket.on('connect', () => socket.end());
socket.on('error', () => {});
socket.on('timeout', () => socket.destroy());
