// Generated by CoffeeScript 1.9.3
(function() {
  var def, expect,
    slice = [].slice;

  expect = require('chai').expect;

  def = require('../index');

  describe('def-inc Module', function() {
    var mixin1, mixin2, mixin3, mixin4, mixin5, mixin6;
    mixin1 = {
      sum: function() {
        var j, len, n, numbers, r;
        numbers = 1 <= arguments.length ? slice.call(arguments, 0) : [];
        r = 0;
        for (j = 0, len = numbers.length; j < len; j++) {
          n = numbers[j];
          r += n;
        }
        return r;
      },
      multiply: function() {
        var j, len, n, numbers, r;
        numbers = 1 <= arguments.length ? slice.call(arguments, 0) : [];
        r = 1;
        for (j = 0, len = numbers.length; j < len; j++) {
          n = numbers[j];
          r *= n;
        }
        return r;
      }
    };
    mixin2 = {
      pow: function(base, num) {
        var i, j, nums, ref;
        nums = [];
        for (i = j = 1, ref = num; 1 <= ref ? j < ref : j > ref; i = 1 <= ref ? ++j : --j) {
          nums.push(num);
        }
        return this.multiply.apply(this, nums);
      }
    };
    mixin3 = {
      increaseByOne: function(n) {
        return this.sum(n, 1);
      }
    };
    mixin4 = {
      _privateAttr: 5,
      publicMethod: function(x) {
        return this._privateMethod(x);
      },
      _privateMethod: function(x) {
        return x * this._privateAttr;
      },
      _privateMethod4: function(x) {
        return x / this._privateAttr;
      },
      _privateMethod2: function(x) {
        return x + this._privateAttr;
      },
      _privateMethod3: function(x) {
        return x - this._privateAttr;
      }
    };
    mixin5 = {
      enable: true,
      preferences: {
        fullScreen: true
      }
    };
    mixin6 = {
      increaseByOne: function(n) {
        return this.sum(n, 1);
      },
      enable: false,
      itemList: ['item5']
    };
    return describe('def.Object method define an object that can inherit attributes from multiple mixins (objects/classes)', function() {
      describe('The def-inc module', function() {
        it('should have an Object method', function() {
          expect(def.Object).to.exist;
          return expect(def.Object).to.be.a('function');
        });
        it('should have a Class method', function() {
          expect(def.Class).to.exist;
          return expect(def.Class).to.be.a('function');
        });
        it('should have a configure method', function() {
          expect(def.settings).to.exist;
          return expect(def.settings).to.be.a('function');
        });
        return describe('When passing an object to the configure method', function() {
          after(function() {
            return def.settings({
              NonEnumUnderscored: true
            });
          });
          it('should return the current value of the specified setting', function() {
            return expect(def.settings('NonEnumUnderscored')).to.be["true"];
          });
          it('should change the current settings of the overriden values', function() {
            def.settings({
              NonEnumUnderscored: false
            });
            return expect(def.settings('NonEnumUnderscored')).to.be["false"];
          });
          return describe('When passing a setting key that does not exist', function() {
            it('should throw and error when trying to retrieve that key', function() {
              var fn;
              fn = function() {
                return def.settings('nonExistentSetting');
              };
              return expect(fn).to["throw"](Error);
            });
            return it('should throw and error when trying to set a setting property that is not already defined', function() {
              var fn;
              fn = function() {
                return def.settings({
                  'nonExistentSetting': true
                });
              };
              return expect(fn).to["throw"](Error);
            });
          });
        });
      });
      describe('The defined object', function() {
        it('should have all properties from the included mixins', function() {
          var definedObj;
          definedObj = def.Object({
            include: [mixin1, mixin2, mixin6]
          });
          return expect(definedObj).to.have.all.keys('increaseByOne', 'sum', 'multiply', 'pow', 'enable', 'itemList');
        });
        it('should be able to call the inherited methods', function() {
          var definedObj;
          definedObj = def.Object({
            include: [mixin1, mixin2, mixin6]
          });
          expect(definedObj.sum(5, 10)).to.equal(15);
          expect(definedObj.increaseByOne(3)).to.equal(4);
          expect(definedObj.multiply(4, 2)).to.equal(8);
          return expect(definedObj.pow(2, 3)).to.equal(9);
        });
        describe('the inherited attributes(data)', function() {
          it('should have been cloned and not just referenced', function() {
            var definedObj;
            definedObj = def.Object({
              include: [mixin5, mixin6]
            });
            delete mixin5.preferences.fullScreen;
            return expect(definedObj.preferences.fullScreen).to.exist;
          });
          return after(function() {
            return mixin5.preferences = {
              fullScreen: true
            };
          });
        });
        describe('When the included mixins or the currently defined Object/Class has a name conflict on an attribute(data)', function() {
          return it('should merge them with the following precedence: From left to right in the included mixins list, being the last one the one with more precedence, only surpassed by the attribute defined in the current Object/Class itself', function() {
            var definedObj;
            definedObj = def.Object({
              include: [mixin5, mixin6],
              increaseByOne: function(n) {
                return this.sum(n, 1);
              },
              preferences: {
                autoPlay: true
              }
            });
            expect(definedObj.enable).to.be["false"];
            expect(definedObj.preferences.fullScreen).to.be["true"];
            return expect(definedObj.preferences.autoPlay).to.be["true"];
          });
        });
        it('should only include the specified attributes from included, when an attr list [] is provided', function() {
          var definedObj;
          definedObj = def.Object({
            include: [mixin1, ['sum'], mixin4, ['publicMethod'], mixin6, ['*']]
          });
          expect(definedObj.sum).to.exist;
          expect(definedObj.multiply).to.not.exist;
          expect(definedObj._privateAttr).to.not.exist;
          expect(definedObj._privateMethod).to.not.exist;
          expect(definedObj._privateMethod2).to.not.exist;
          return expect(definedObj._privateMethod3).to.not.exist;
        });
        it('should be able to exclude an attribute from a baked baseObject, when an "!" flag is provided e.g: ["!", "attr1", "attr2"]', function() {
          var definedObj;
          definedObj = def.Object({
            include: [mixin1, ['!', 'multiply'], mixin6, ['*']]
          });
          expect(definedObj.sum).to.exist;
          return expect(definedObj.multiply).to.not.exist;
        });
        it('should include all attributes from a baked baseObject when an ["*"] (includeAll)  flag is provided', function() {
          var definedObj;
          definedObj = def.Object({
            include: [mixin1, ['*'], mixin6, ['*']]
          });
          expect(definedObj.sum).to.exist;
          expect(definedObj.multiply).to.exist;
          return expect(definedObj.increaseByOne).to.exist;
        });
        it('should exclude all attributes from a baked baseObject when an ["!"] (excludeAll) flag is provided', function() {
          var definedObj;
          definedObj = def.Object({
            include: [mixin1, ['!'], mixin6, ['*']]
          });
          expect(definedObj.sum).to.not.exist;
          expect(definedObj.multiply).to.not.exist;
          return expect(definedObj.increaseByOne).to.exist;
        });
        it('should have the _.super property hidden and frozen (non: enumerable, configurable, writable)', function() {
          var definedObj;
          definedObj = def.Object({
            include: [mixin1, mixin6, ['*']]
          });
          expect(definedObj.propertyIsEnumerable('_super')).to.be["false"];
          return expect(Object.isFrozen(definedObj._super)).to.be["true"];
        });
        it('should include attributes from constructor functions/classes prototypes, when constructor is excluded', function() {
          var Parent, definedObj;
          Parent = (function() {
            function Parent() {}

            Parent.prototype.someMethod = function() {
              return 'x';
            };

            return Parent;

          })();
          definedObj = def.Object({
            include: [Parent, ['!', 'constructor'], mixin6, ['*']]
          });
          expect(definedObj.someMethod).to.exist;
          return expect(definedObj.someMethod()).to.equal('x');
        });
        it('should throw an error when a constructor method is defined', function() {
          var defObject;
          defObject = function() {
            return def.defObject({
              constructor: function() {
                return true;
              }
            });
          };
          return expect(defObject).to["throw"](Error);
        });
        it('should not include static attributes (classAttributes) from constructor functions/classes', function() {
          var Parent, definedObj;
          Parent = (function() {
            function Parent() {}

            Parent.staticMethod = function() {
              return 'y';
            };

            return Parent;

          })();
          definedObj = def.Object({
            include: [Parent, ['!', 'constructor']]
          });
          return expect(definedObj.staticMethod).to.not.exist;
        });
        describe('When the accessors property is defined', function() {
          describe('In the object passed as argument to the def method (Object/Class)', function() {
            var definedObj;
            definedObj = def.Object({
              accessors: ['fullName'],
              _name: 'John',
              _lastName: 'Doe',
              fullName: {
                get: function() {
                  return this._name + " " + this._lastName;
                },
                set: function(fullName) {
                  var nameParts;
                  nameParts = fullName.split(' ');
                  this._name = nameParts[0];
                  return this._lastName = nameParts[1];
                }
              }
            });
            it('should set the getter to the specified attribute', function() {
              return expect(definedObj.fullName).to.equal('John Doe');
            });
            return it('should set the setter to the specified attribute', function() {
              definedObj.fullName;
              return expect(definedObj.fullName).to.equal('John Doe');
            });
          });
          return describe('In a fn passed as argument to the def method (Object/Class)', function() {
            var definedObj;
            definedObj = def.Object(function() {
              var lastName, name;
              name = 'John';
              lastName = 'Doe';
              this.accessors = ['fullName'];
              return this.fullName = {
                get: function() {
                  return name + " " + lastName;
                },
                set: function(fullName) {
                  var nameParts;
                  nameParts = fullName.split(' ');
                  name = nameParts[0];
                  return lastName = nameParts[1];
                }
              };
            });
            it('should set the getter to the specified attribute', function() {
              return expect(definedObj.fullName).to.equal('John Doe');
            });
            return it('should set the setter to the specified attribute', function() {
              definedObj.fullName;
              return expect(definedObj.fullName).to.equal('John Doe');
            });
          });
        });
        describe('when using a function as argument instead of an obj', function() {
          it('should be able to call truly static private attributes, when defining it as a local variable of the fn', function() {
            var definedObj;
            definedObj = def.Object(function() {
              var privateVar;
              privateVar = 5;
              this.set = function(n) {
                return privateVar = n;
              };
              return this.get = function() {
                return privateVar;
              };
            });
            expect(definedObj.privateVar).to.not.exist;
            expect(definedObj.get()).to.equal(5);
            definedObj.set(4);
            return expect(definedObj.get()).to.equal(4);
          });
          return it('should be able to call truly private methods, when defining it as a local variable of the fn', function() {
            var definedObj;
            definedObj = def.Object(function() {
              var square;
              this.calculate = function(n) {
                return square(n);
              };
              return square = function(n) {
                return n * n;
              };
            });
            return expect(definedObj.calculate(5)).to.equal(25);
          });
        });
        describe('When an attribute(Only methods) is marked with the ~ flag in the filter array, e.g: ["~methodName"]', function() {
          it('should bind the method context to the original obj (parent) instead of the target obj', function() {
            var definedObj;
            definedObj = def.Object({
              include: [mixin4, ['~publicMethod']]
            });
            expect(definedObj._privateAttr).to.not.exist;
            expect(definedObj._privateMethod).to.not.exist;
            expect(definedObj.publicMethod).to.exist;
            return expect(definedObj.publicMethod(2)).to.equal(10);
          });
          return it('should ignore ~ when using the exclude flag', function() {
            var definedObj;
            definedObj = def.Object({
              include: [mixin4, ['!', '~_privateMethod']]
            });
            return expect(definedObj._privateMethod).to.not.exist;
          });
        });
        describe('When inheriting from multiple objects', function() {
          return it('should include/inherit attributes in the opposite order they were passed to the function, so the last ones takes precedence over the first ones, when an attribute is found in more than one object', function() {
            var definedObj, definedObj2;
            definedObj = def.Object({
              include: [
                mixin1, {
                  multiply: function(x) {
                    return x;
                  }
                }
              ]
            });
            expect(definedObj.multiply(5)).to.equal(5);
            definedObj2 = def.Object({
              include: [definedObj, mixin1]
            });
            return expect(definedObj2.multiply(5, 5)).to.equal(25);
          });
        });
        describe('When redefining a function in the receiving object', function() {
          return it('should be able to call the parent obj method via the _super obj', function() {
            var definedObj;
            definedObj = def.Object({
              include: [mixin1],
              multiply: function() {
                var numbers;
                numbers = 1 <= arguments.length ? slice.call(arguments, 0) : [];
                return this._super.multiply.apply(this, numbers) * 2;
              }
            });
            return expect(definedObj.multiply(2, 2)).to.equal(8);
          });
        });
        return describe('When a property is defined with a leading underscore in the passed argument object/fn', function() {
          it('should have that property marked as nonEnumerable', function() {
            var definedObj;
            def.settings({
              NonEnumUnderscored: true
            });
            definedObj = def.Object({
              calculation: function(x) {
                return this._pseudoPrivateSquare(x);
              },
              _pseudoPrivateSquare: function(x) {
                return x * x;
              }
            });
            return expect(Object.keys(definedObj)).to.eql(['calculation']);
          });
          return it('should not have that property marked as nonEnumerable if the "nonEnumOnPrivate" setting is turned off', function() {
            var definedObj;
            def.settings({
              NonEnumUnderscored: false
            });
            definedObj = def.Object({
              calculation: function(x) {
                return this._pseudoPrivateSquare(x);
              },
              _pseudoPrivateSquare: function(x) {
                return x * x;
              }
            });
            expect(Object.keys(definedObj)).to.eql(['calculation', '_pseudoPrivateSquare']);
            return def.settings({
              NonEnumUnderscored: true
            });
          });
        });
      });
      return describe('def.Class method', function() {
        it('should define a js "Class" when a constructor method is defined', function() {
          var definedClass;
          definedClass = def.Class({
            constructor: function() {
              return true;
            }
          });
          expect(definedClass).to.be.a('function');
          return expect(new definedClass).to.be.an('object');
        });
        it('should throw an error when a constructor method is not defined', function() {
          var defClass;
          defClass = function() {
            return def.Class({
              someMethod: function() {
                return true;
              }
            });
          };
          return expect(defClass).to["throw"](Error);
        });
        describe('When class attributes (static) are defined in a parent class', function() {
          return it('should add them to the defined class as static attributes', function() {
            var Parent, definedClass, instanceOfBaked;
            Parent = (function() {
              function Parent() {}

              Parent.staticMethod = function() {
                return 'y';
              };

              return Parent;

            })();
            definedClass = def.Class({
              include: [Parent, ['!', 'attr']],
              constructor: function() {
                return true;
              }
            });
            expect(definedClass.staticMethod).to.exist;
            expect(definedClass.staticMethod()).to.equal('y');
            instanceOfBaked = new definedClass;
            return expect(instanceOfBaked.staticMethod).to.not.exist;
          });
        });
        return describe('When any of the included element defines a constructor method', function() {
          return it('should be a constructor function that calls the constructor defined in the receiving obj ', function() {
            var definedObj, instance;
            definedObj = def.Class({
              include: [
                {
                  constructor: function(msg) {
                    return this.msg = msg;
                  }
                }
              ],
              constructor: function() {
                return this._super.constructor(this, "I'm baked");
              }
            });
            instance = new definedObj("I'm baked");
            return expect(instance.msg).to.equal("I'm baked");
          });
        });
      });
    });
  });

}).call(this);

//# sourceMappingURL=index.spec.js.map
