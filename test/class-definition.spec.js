// Generated by CoffeeScript 1.10.0
(function() {
  describe('def.Class method', function() {
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
    describe('When using the "merges" directive', function() {
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
            merges: [Parent, ['!', 'attr']],
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
      return describe('When any of the merged element defines a constructor method', function() {
        return describe('it should not be available via @_super fn call', function() {
          var definedClass, instance, superClass;
          superClass = def.Class({
            constructor: function(msg) {
              return this.msg = msg;
            }
          });
          definedClass = def.Class({
            merges: [superClass],
            constructor: function() {
              return superClass.call(this, "I'm baked");
            }
          });
          instance = new definedClass("I'm baked");
          expect(instance.msg).to.equal("I'm baked");
          return expect(instance._super).to.be.an("object");
        });
      });
    });
    describe('When using the "extends" directive', function() {
      var User;
      User = def.Class({
        constructor: function(name) {
          return this.userName = name;
        },
        getName: function() {
          return this.userName;
        }
      });
      return describe('When defining a class', function() {
        var Admin, userName;
        Admin = def.Class({
          "extends": User,
          constructor: function(name, clearanceLvl) {
            this.clearanceLvl = clearanceLvl;
            return this._super.constructor.call(this, name);
          },
          someMethod: function() {
            return this.getName();
          }
        });
        userName = 'zaggen';
        it('should have all properties from the passed Class', function() {
          return expect(Admin.prototype.__proto__).to.have.all.keys('constructor', 'getName', '_super');
        });
        it('should have access to the parent Class constructor via the @_super fn', function() {
          var adminUser;
          adminUser = new Admin(userName, 5);
          expect(adminUser._super).to.be.an('object');
          expect(adminUser.userName).to.equal(userName);
          return expect(adminUser.someMethod()).to.equal(userName);
        });
        return it('should have access to the parent Class methods via the @_super obj', function() {
          var adminUser;
          adminUser = new Admin(userName, 5);
          return expect(adminUser.someMethod()).to.equal(userName);
        });
      });
    });
    return describe('def.Abstract method', function() {
      it('should define an object, just as def.object method when no constructor is defined', function() {
        var abstractObj;
        abstractObj = def.Abstract({
          someMethod: function() {
            return true;
          }
        });
        expect(abstractObj).to.be.an('object');
        return expect(abstractObj.someMethod).to.exist;
      });
      it('should define a Class when the constructor is defined', function() {
        var abstractClass;
        abstractClass = def.Abstract({
          constructor: function() {
            return this._x = 5;
          },
          someMethod: function() {
            return true;
          }
        });
        return expect(abstractClass).to.be.a('function');
      });
      return it('should define a Class that can be used to extend classes and objects', function() {
        var AbstractClass, concreteClass, instance;
        AbstractClass = def.Abstract({
          constructor: function() {
            return this._x = 5;
          },
          someMethod: function() {
            return true;
          }
        });
        concreteClass = def.Class({
          "extends": AbstractClass,
          constructor: function() {
            return this._x = this._super.constructor();
          }
        });
        instance = new concreteClass;
        return expect(instance._x).to.exist;
      });
    });
  });

}).call(this);

//# sourceMappingURL=class-definition.spec.js.map
