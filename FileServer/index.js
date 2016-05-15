'use strict'

var express = require('express');
var fs = require('fs');
var app = express();

var FILE_NAME = 'data/data.json';

var bodyParser = require('body-parser')
app.use( bodyParser.json() );       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({     // to support URL-encoded bodies
  extended: true
}));

app.all('/', function(req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "X-Requested-With");
  next();
});

app.post('/upload', function (request, response) {
	console.log('uploading');
	var data = request.body.data;

	fs.writeFile(FILE_NAME, data, function (error) {
		if (error) console.log('write error');
	});
});

app.get('/', function (request, response) {
    var stat = fs.statSync(FILE_NAME);
    console.log('get request');

    response.writeHead(200, {
        'Content-Type': 'text/json',
        'Content-Length': stat.size
    });

    var readStream = fs.createReadStream(FILE_NAME);
    readStream.pipe(response);
});

app.listen(3000, function() {
	console.log('listening on 3000');
});
