// Generated by CoffeeScript 1.9.3
(function() {
  var _, defIncModule,
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  _ = require('lodash');

  defIncModule = {
    def: function(propsDefiner, type) {
      var accessors, attr, baseObj, fn, i, includedTypes, j, key, len, newObj, newObjAtrrs, obj, ref, reservedKeys;
      if (type == null) {
        type = 'object';
      }
      obj = {};
      if (_.isFunction(propsDefiner)) {
        propsDefiner.call(obj);
      } else {
        obj = propsDefiner;
      }
      console.log('obj', obj, "\n");
      includedTypes = obj.include_;
      accessors = obj.accessors_;
      newObj = {};
      newObj._super = {};
      newObjAtrrs = _.mapValues(obj, function(val) {
        return true;
      });

      /*@_checkIfValid(obj, type) */
      reservedKeys = ['include_', 'prototype_', 'accessors_'];
      for (key in obj) {
        attr = obj[key];
        if (!_.contains(reservedKeys, key)) {
          newObj[key] = attr;
        }
      }
      console.log('newObj', newObj, "\n");
      if (accessors != null) {
        this._defineAccessors(newObj, accessors);
      }
      this._filterArgs(includedTypes);
      this.staticMethods = {};
      ref = this.baseObjs;
      for (i = j = 0, len = ref.length; j < len; i = ++j) {
        baseObj = ref[i];
        this._filter.set(this.options[i]);
        for (key in baseObj) {
          if (!hasProp.call(baseObj, key)) continue;
          attr = baseObj[key];
          if (!this._filter.skip(key)) {
            if (_.isFunction(attr)) {
              fn = attr;
              fn = this.useParentContext.hasOwnProperty(key) ? fn.bind(baseObj) : fn;
              if (newObjAtrrs.hasOwnProperty(key)) {
                if (key === 'constructor') {
                  this._setSuperConstructor(newObj, fn);
                } else {
                  newObj._super[key] = fn;
                }
              } else {
                newObj[key] = newObj._super[key] = fn;
              }
            } else {
              if (!newObjAtrrs.hasOwnProperty(key)) {
                newObj[key] = _.cloneDeep(attr);
              } else if (_.isArray(attr)) {
                newObj[key] = newObj[key].concat(attr);
              } else if (_.isObject(attr) && key !== '_super') {
                newObj[key] = _.merge(newObj[key], attr);
              }
            }
          }
        }
      }
      this._freezeAndHideAttr(newObj, '_super');
      if (type === 'class') {
        return this._makeConstructor(newObj);
      } else {
        return newObj;
      }
    },
    _checkIfValid: function(obj, type) {
      var hasConstructor, msg;
      hasConstructor = obj.hasOwnProperty('constructor');
      if (type === 'object' && hasConstructor) {
        msg = 'Constructor is a reserved keyword, to define classes\nwhen using def.Class method, but you are\ndefining an object';
        throw new Error(msg);
      } else if (type === 'class' && hasConstructor) {
        msg('No constructor defined in the object. To create a class a constructor must be defined as a key');
        throw new Error(msg);
      }
    },
    _defineAccessors: function(obj, accessorsList) {
      var j, len, propertyName, results;
      results = [];
      for (j = 0, len = accessorsList.length; j < len; j++) {
        propertyName = accessorsList[j];
        results.push(Object.defineProperty(obj, propertyName, obj[propertyName]));
      }
      return results;
    },
    _setSuperConstructor: function(target, constructor) {
      return target._super.constructor = function() {
        var superArgs;
        superArgs = 1 <= arguments.length ? slice.call(arguments, 0) : [];
        return constructor.apply(superArgs.shift(), superArgs);
      };
    },
    _filterArgs: function(args) {
      this.baseObjs = [];
      this.options = [];
      this.useParentContext = {};
      return _.each(args, (function(_this) {
        return function(arg) {
          var fn, obj;
          if (!_.isObject(arg)) {
            throw new Error('BakeIn only accepts objects/arrays/fns e.g (fn/{} parent objects/classes or an [] with options)');
          } else if (_this._isOptionArr(arg)) {
            return _this.options.push(_this._makeOptionsObj(arg));
          } else if (_.isFunction(arg)) {
            fn = arg;
            obj = _.merge({}, fn, fn.prototype);
            obj.constructor = fn;
            return _this.baseObjs.push(obj);
          } else {
            return _this.baseObjs.push(arg);
          }
        };
      })(this));
    },
    _isOptionArr: function(arg) {
      var isStringsArray;
      if (_.isArray(arg)) {
        isStringsArray = _.every(arg, function(item) {
          if (_.isString(item)) {
            return true;
          } else {
            return false;
          }
        });
        if (isStringsArray) {
          return true;
        } else {
          throw new Error('Array contains illegal types: The config [] should only contain strings i.e: (attr names or filter symbols (! or *) )');
        }
      } else {
        return false;
      }
    },
    _makeOptionsObj: function(attrNames) {
      var filterKey;
      filterKey = attrNames[0];
      switch (filterKey) {
        case '!':
          if (attrNames[1] != null) {
            attrNames.shift();
            attrNames = this._filterParentContextFlag(attrNames, true);
            return {
              'exclude': attrNames
            };
          } else {
            return {
              'excludeAll': true
            };
          }
          break;
        case '*':
          return {
            'includeAll': true
          };
        default:
          attrNames = this._filterParentContextFlag(attrNames);
          return {
            'include': attrNames
          };
      }
    },
    _filterParentContextFlag: function(attrNames, warningOnMatch) {
      var attrName, j, len, newAttrNames;
      newAttrNames = [];
      for (j = 0, len = attrNames.length; j < len; j++) {
        attrName = attrNames[j];
        if (attrName.charAt(0) === '~') {
          if (warningOnMatch) {
            console.warn('The ~ should only be used when including methods, not excluding them');
          }
          attrName = attrName.replace('~', '');
          newAttrNames.push(attrName);
          this.useParentContext[attrName] = true;
        } else {
          newAttrNames.push(attrName);
        }
      }
      return newAttrNames;
    },
    _checkForBalance: function(baseObjs, options) {
      if (options.length > 0 && baseObjs.length !== options.length) {
        throw new Error('Invalid number of conf-options: If you provide a conf obj, you must provide one for each baseObj');
      }
      return true;
    },
    _filter: {
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
    },
    _freezeAndHideAttr: function(obj, attributeName) {
      if (obj[attributeName] != null) {
        Object.defineProperty(obj, attributeName, {
          enumerable: false
        });
        return Object.freeze(obj[attributeName]);
      }
    },
    _makeConstructor: function(obj) {
      var fn;
      fn = function() {
        var args;
        args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
        return obj.constructor.apply(this, args);
      };
      fn.prototype = obj;
      return fn;
    }
  };

  module.exports = {
    Object: function(obj) {
      return defIncModule.def.call(defIncModule, obj, 'object');
    },
    Class: function(obj) {
      return defIncModule.def.call(defIncModule, obj, 'class');
    }
  };

}).call(this);

//# sourceMappingURL=index.js.map
