// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var World, _, avgCarSpeed, avgInstantSpeed, avgSpeed, experiment, experiment4, experiment5, fs, getParams, random, settings;

  random = Math.random;

  require('./helpers');

  World = require('./model/world');

  _ = require('underscore');

  settings = require('./settings');

  fs = require('fs');

  avgInstantSpeed = function(setupCallback) {
    var i, j, results, world;
    world = new World();
    world.generateMap();
    world.carsNumber = 400;
    if (typeof setupCallback === "function") {
      setupCallback(world);
    }
    results = [];
    for (i = j = 0; j <= 1000; i = ++j) {
      world.onTick(0.2);
      results.push(world.instantSpeed);
    }
    return (results.reduce(function(a, b) {
      return a + b;
    })) / results.length;
  };

  avgCarSpeed = function(setupCallback) {
    var i, j, world;
    world = new World();
    world.generateMap();
    world.carsNumber = 100;
    if (typeof setupCallback === "function") {
      setupCallback(world);
    }
    for (i = j = 0; j <= 3000; i = ++j) {
      world.onTick(0.2);
    }
    return world.avgCarsSpeed;
  };

  avgSpeed = function(setupCallback) {
    var i, j, results, world;
    world = new World();
    world.generateMap8();
    world.carsNumber = 50;
    if (typeof setupCallback === "function") {
      setupCallback(world);
    }
    results = [];
    for (i = j = 0; j <= 2000; i = ++j) {
      world.onTick(0.2);
      results.push(world.instantSpeed);
    }
    return [
      (results.reduce(function(a, b) {
        return a + b;
      })) / results.length, world.avgCarsSpeed
    ];
  };

  getParams = function(world) {
    var i, id, params;
    params = (function() {
      var ref, results1;
      ref = world.intersections.all();
      results1 = [];
      for (id in ref) {
        i = ref[id];
        results1.push(i.controlSignals.flipMultiplier);
      }
      return results1;
    })();
    return params;
  };

  settings.lightsFlipInterval = 200;

  experiment = function() {
    var it, j, out, result, result_max1, result_max2, x, x_max1, x_max2;
    out = fs.createWriteStream('./experiments/randomMap/flip200car50.data');
    out.write('"flipMult" "avgInstantSpeed" "avgCarSpeed"\n');
    x_max1 = -1;
    result_max1 = -1;
    x_max2 = -1;
    result_max2 = -1;
    for (it = j = 0; j <= 100; it = ++j) {
      x = random();
      result = avgSpeed(function(world) {
        var i, id, ref;
        ref = world.intersections.all();
        for (id in ref) {
          i = ref[id];
          i.controlSignals.flipMultiplier = x;
        }
        return getParams(world);
      });
      console.log(it);
      out.write('"' + (it + 1) + '" ' + (x * settings.lightsFlipInterval) + ' ' + result[0] + ' ' + result[1] + '\n');
      if (result[0] > result_max1) {
        x_max1 = x;
        result_max1 = result[0];
      }
      if (result[1] > result_max2) {
        x_max2 = x;
        result_max2 = result[1];
      }
    }
    out.write('max1: ' + (x_max1 * settings.lightsFlipInterval) + ' ' + result_max1 + ' ' + 0 + '\n');
    return out.write('max2: ' + (x_max2 * settings.lightsFlipInterval) + ' ' + 0 + ' ' + result_max2 + '\n');
  };

  experiment();

  experiment4 = function() {
    var it, j, out, result, result_max, x, x_max;
    out = fs.createWriteStream('./experiments/avgInstance/flip50.data');
    out.write('"flipMult" "avgSpeed"\n');
    x_max = -1;
    result_max = -1;
    for (it = j = 0; j <= 60; it = ++j) {
      x = random();
      result = avgInstantSpeed(function(world) {
        var i, id, ref;
        ref = world.intersections.all();
        for (id in ref) {
          i = ref[id];
          i.controlSignals.flipMultiplier = x;
        }
        return getParams(world);
      });
      out.write('"' + (it + 1) + '" ' + ((0.1 + 0.05 * x) * settings.lightsFlipInterval) + ' ' + result + '\n');
      if (result > result_max) {
        x_max = x;
        result_max = result;
      }
    }
    return out.write('max: ' + ((0.1 + 0.05 * x_max) * settings.lightsFlipInterval) + ' ' + result_max + '\n');
  };

  experiment5 = function() {
    var it, j, out, result, result_max, x, x_max;
    out = fs.createWriteStream('./experiments/avgCar/flip400test5.data');
    out.write('"flipMult" "avgSpeed"\n');
    x_max = -1;
    result_max = -1;
    for (it = j = 0; j <= 100; it = ++j) {
      x = random();
      result = avgCarSpeed(function(world) {
        var i, id, ref;
        ref = world.intersections.all();
        for (id in ref) {
          i = ref[id];
          i.controlSignals.flipMultiplier = x;
        }
        return getParams(world);
      });
      out.write('"' + (it + 1) + '" ' + (x * settings.lightsFlipInterval) + ' ' + result + '\n');
      if (result > result_max) {
        x_max = x;
        result_max = result;
      }
    }
    return out.write('max: ' + (x_max * settings.lightsFlipInterval) + ' ' + result_max + '\n');
  };

}).call(this);

//# sourceMappingURL=two_lights.js.map
