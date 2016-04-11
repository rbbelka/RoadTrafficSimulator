// Generated by CoffeeScript 1.10.0
(function() {
  'use strict';
  var ControlSignals, Intersection, Rect, _;

  require('../helpers');

  _ = require('underscore');

  ControlSignals = require('./control-signals');

  Rect = require('../geom/rect');

  Intersection = (function() {
    function Intersection(rect) {
      this.rect = rect;
      this.id = _.uniqueId('intersection');
      this.roads = [];
      this.inRoads = [];
      this.controlSignals = new ControlSignals(this);
    }

    Intersection.copy = function(intersection) {
      var result;
      intersection.rect = Rect.copy(intersection.rect);
      result = Object.create(Intersection.prototype);
      _.extend(result, intersection);
      result.roads = [];
      result.inRoads = [];
      result.controlSignals = ControlSignals.copy(result.controlSignals, result);
      return result;
    };

    Intersection.prototype.toJSON = function() {
      var obj;
      return obj = {
        id: this.id,
        rect: this.rect,
        controlSignals: this.controlSignals
      };
    };

    Intersection.prototype.update = function() {
      var i, j, len, len1, ref, ref1, results, road;
      ref = this.roads;
      for (i = 0, len = ref.length; i < len; i++) {
        road = ref[i];
        road.update();
      }
      ref1 = this.inRoads;
      results = [];
      for (j = 0, len1 = ref1.length; j < len1; j++) {
        road = ref1[j];
        results.push(road.update());
      }
      return results;
    };

    return Intersection;

  })();

  module.exports = Intersection;

}).call(this);

//# sourceMappingURL=intersection.js.map
