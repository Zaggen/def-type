// Generated by CoffeeScript 1.10.0
(function() {
  var _, filter;

  _ = require('lodash');

  filter = {
    set: function(conf) {
      if (conf != null) {
        this.mode = _.keys(conf)[0];
        this.attrFilters = conf[this.mode];
        if (_.isString(this.attrFilters)) {
          return this.attrFilters = this.attrFilters.split(',');
        }
      } else {
        this.mode = void 0;
        return this.attrFilters = void 0;
      }
    },
    skip: function(key) {
      var keyIndex;
      switch (this.mode) {
        case 'include':
          if (this.attrFilters.length === 0) {
            return true;
          }
          keyIndex = _.indexOf(this.attrFilters, key);
          if (keyIndex >= 0) {
            _.pullAt(this.attrFilters, keyIndex);
            return false;
          } else {
            return true;
          }
          break;
        case 'exclude':
          if (this.attrFilters.length === 0) {
            return false;
          }
          keyIndex = _.indexOf(this.attrFilters, key);
          if (keyIndex >= 0) {
            _.pullAt(this.attrFilters, keyIndex);
            return true;
          } else {
            return false;
          }
          break;
        case 'includeAll':
          return false;
        case 'excludeAll':
          return true;
        default:
          return false;
      }
    }
  };

  module.exports = filter;

}).call(this);

//# sourceMappingURL=properties-filter.js.map
