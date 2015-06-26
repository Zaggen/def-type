expect = require('chai').expect
def = require('../index')

describe 'def-inc Module', ->
  mixin1 =
    sum: (numbers...)->
      r = 0
      r += n for n in numbers
      return r

    multiply: (numbers...)->
      r = 1
      r *= n for n in numbers
      return r

  mixin2 =
    pow: (base, num)->
      nums = []
      for i in [1...num]
        nums.push(num)
      return @multiply.apply(this, nums)

  mixin3 =
    increaseByOne: (n)->
      @sum(n, 1)


  mixin4 =
    _privateAttr: 5
    publicMethod: (x)->  @_privateMethod(x)
    _privateMethod: (x)-> x * @_privateAttr
    _privateMethod4: (x)-> x / @_privateAttr
    _privateMethod2: (x)-> x + @_privateAttr
    _privateMethod3: (x)-> x - @_privateAttr

  objWithAttrs =
    enable: true
    preferences:
      fullScreen: true

  baseObj5 =
    increaseByOne: (n)->  @sum(n, 1)
    enable: false
    itemList: ['item5']

  describe 'def.Object method define an object that can inherit attributes from multiple objects/classes', ->

    describe 'The def-inc module', ->
      it 'should have an Object method', ->
        expect(def.Object).to.exist
        expect(def.Object).to.be.a('function')

      it 'should have a Class method', ->
        expect(def.Class).to.exist
        expect(def.Class).to.be.a('function')

    describe 'The defined object', ->

      it 'should have all methods from the included mixins and their original attributes', ->
        definedObj = def.Object( include_: [mixin1, mixin2, baseObj5] )
        expect(definedObj).to.have.all.keys('increaseByOne', 'sum', 'multiply', 'pow', 'enable', 'itemList')

      it 'should be able to call the included methods', ->
        definedObj = def.Object( include_: [mixin1, mixin2, baseObj5])
        expect(definedObj.sum(5, 10)).to.equal(15)
        expect(definedObj.increaseByOne(3)).to.equal(4)
        expect(definedObj.multiply(4, 2)).to.equal(8)
        expect(definedObj.pow(2, 3)).to.equal(9)

      it 'should include(clone) attributes from the objects in the include_ array', ->
        definedObj = def.Object(include_: [objWithAttrs, baseObj5])
        expect(definedObj.enable).to.exist
        expect(definedObj.preferences.fullScreen).to.exist.and.to.be.true
        delete objWithAttrs.preferences.fullScreen
        expect(definedObj.preferences.fullScreen).to.exist
        # Lets reset objWithAttrs
        objWithAttrs.preferences = {fullScreen: true}


      it 'should not clone an attribute from a base object if its being defined in the obj passed to def.Object', ->
        definedObj = def.Object(
          include_: [objWithAttrs]
          increaseByOne: (n)->  @sum(n, 1)
          enable: false
          itemList: ['item5']
        )
        expect(definedObj.enable).to.be.false

      it 'should have the attributes of the last baseObj that had an attr nameConflict (Override attrs in arg passing order)', ->
        definedObj = def.Object(include_: [{overridden: false, itemList: ['item2']}, {overridden: true}, baseObj5])
        expect(definedObj.overridden).to.be.true
        expect(definedObj.itemList).to.deep.equal(['item5'])

      it 'should be able to only include the specified attributes from a baked baseObject, when an attr list [] is provided', ->
        definedObj = def.Object( include_: [mixin1, ['sum'], mixin4, ['publicMethod'], baseObj5, ['*']] )
        expect(definedObj.sum).to.exist
        expect(definedObj.multiply).to.not.exist
        expect(definedObj._privateAttr).to.not.exist
        expect(definedObj._privateMethod).to.not.exist
        expect(definedObj._privateMethod2).to.not.exist
        expect(definedObj._privateMethod3).to.not.exist

      it 'should be able to exclude an attribute from a baked baseObject, when an "!" flag is provided e.g: ["!", "attr1", "attr2"]', ->
        definedObj = def.Object( include_: [mixin1, ['!', 'multiply'], baseObj5, ['*'] ] )
        expect(definedObj.sum).to.exist
        expect(definedObj.multiply).to.not.exist


      it 'should include all attributes from a baked baseObject when an ["*"] (includeAll)  flag is provided', ->
        definedObj = def.Object( include_: [mixin1, ['*'], baseObj5, ['*'] ] )
        expect(definedObj.sum).to.exist
        expect(definedObj.multiply).to.exist
        expect(definedObj.increaseByOne).to.exist

      it 'should exclude all attributes from a baked baseObject when an ["!"] (excludeAll) flag is provided', ->
        definedObj = def.Object( include_: [mixin1, ['!'], baseObj5, ['*'] ] )
        expect(definedObj.sum).to.not.exist
        expect(definedObj.multiply).to.not.exist
        expect(definedObj.increaseByOne).to.exist

      it 'should have the _.super property hidden and frozen (non: enumerable, configurable, writable)', ->
        definedObj = def.Object( include_: [mixin1, baseObj5, ['*']])
        expect(definedObj.propertyIsEnumerable('_super')).to.be.false
        expect(Object.isFrozen(definedObj._super)).to.be.true

      it 'should include attributes from constructor functions/classes prototypes, when constructor is excluded', ->
        class Parent
          someMethod: -> 'x'

        definedObj = def.Object( include_: [ Parent, ['!', 'constructor'], baseObj5, ['*'] ] )
        expect(definedObj.someMethod).to.exist
        expect(definedObj.someMethod()).to.equal('x')

      describe 'When the accessors_ property is defined', ->
        ###describe 'In the object passed as argument to the def method (Object/Class)', ->
          definedObj = def.Object(
            accessors_: ['fullName']
            _name: 'John'
            _lastName: 'Doe'
            fullName:
              get: -> "#{@_name} #{@_lastName}"
              set: (fullName)->
                nameParts = fullName.split(' ')
                @_name = nameParts[0]
                @_lastName = nameParts[1]
          )
          it 'should set the getter to the specified attribute', ->
            expect(definedObj.fullName).to.equal('John Doe')

          it 'should set the setter to the specified attribute', ->
            definedObj.fullName
            expect(definedObj.fullName).to.equal('John Doe')###

        describe.only 'In a fn passed as argument to the def method (Object/Class)', ->
          definedObj = def.Object ->
            name = 'John'
            lastName =  'Doe'
            @accessors_ = ['fullName']
            @fullName = {
              get: -> "#{name} #{lastName}"
              set: (fullName)->
                nameParts = fullName.split(' ')
                name = nameParts[0]
                lastName = nameParts[1]
            }
            @hp = 234

          console.log 'definedObj', definedObj

          it 'should set the getter to the specified attribute', ->
            expect(definedObj.fullName).to.equal('John Doe')

          it 'should set the setter to the specified attribute', ->
            definedObj.fullName
            expect(definedObj.fullName).to.equal('John Doe')


      describe 'when using a function as argument instead of an obj', ->
        it 'should be able to call truly static private attributes, when defining it as a local variable of the fn', ->
          definedObj = def.Object ->
            # Private Attrs
            privateVar = 5
            # Public Attrs
            @set = (n)-> privateVar = n
            @get = -> privateVar

            return this

          expect(definedObj.privateVar).to.not.exist
          expect(definedObj.get()).to.equal(5)
          definedObj.set(4)
          expect(definedObj.get()).to.equal(4)

        it 'should be able to call truly private methods, when defining it as a local variable of the fn', ->
          definedObj = def.Object ->
            @calculate = (n)-> square(n)
            # Private Methods
            square = (n)-> n * n
            return this

          console.log definedObj
          expect(definedObj.calculate(5)).to.equal(25)

      describe 'When an attribute(Only methods) is marked with the ~ flag in the filter array, e.g: ["~methodName"]', ->
        it 'should bind the method context to the original obj (parent) instead of the target obj', ->
          definedObj = def.Object( include_: [ mixin4, ['~publicMethod'] ])
          expect(definedObj._privateAttr).to.not.exist
          expect(definedObj._privateMethod).to.not.exist
          expect(definedObj.publicMethod).to.exist
          expect(definedObj.publicMethod(2)).to.equal(10)
        it 'should ignore ~ when using the exclude flag', ->
          definedObj = def.Object( include_: [ mixin4, ['!', '~_privateMethod'] ])
          expect(definedObj._privateMethod).to.not.exist

      describe 'When inheriting from multiple objects', ->
        it 'should include/inherit attributes in the opposite order they were passed to the function, so the last ones takes
            precedence over the first ones, when an attribute is found in more than one object', ->

          # This avoids the diamond problem with multiple inheritance
          definedObj = def.Object( include_: [ mixin1, {multiply: (x)-> x} ])
          expect(definedObj.multiply(5)).to.equal(5)
          definedObj2 = def.Object( include_: [ definedObj, mixin1 ])
          expect(definedObj2.multiply(5, 5)).to.equal(25)

      describe 'When redefining a function in the receiving object', ->
        it 'should be able to call the parent obj method via the _super obj', ->
          definedObj = def.Object(
            include_: [ mixin1 ]
            multiply: (numbers...)->
              @_super.multiply.apply(this, numbers) * 2
          )

          expect(definedObj.multiply(2, 2)).to.equal(8)

    describe 'def.Class method defines a Class/Type/Constructor that can inherit attributes from multiple objects/classes', ->

      it 'should include static attributes (classAttributes) from constructor functions/classes, to the resulting constructor, when one is defined', ->
        class Parent
          @staticMethod: -> 'y'

        definedObj = def.Class(
          include_: [ Parent ]
          constructor:-> true
        )
        instanceOfBaked = new definedObj
        expect(instanceOfBaked.staticMethod).to.exist
        expect(instanceOfBaked.staticMethod()).to.equal('y')

      it 'should not include static attributes (classAttributes) from constructor functions/classes, when a constructor is not defined', ->
        class Parent
          @staticMethod: -> 'y'

        definedObj = def.Object( include_: [ Parent, ['!', 'constructor'] ])
        expect(definedObj.staticMethod).to.exist
        expect(definedObj.staticMethod()).to.equal('y')

      describe 'When any of the included element defines a constructor method', ->
        it 'should be a constructor function that calls the constructor defined in the receiving obj ', ->
          definedObj = def.Class(
            include_: [ {constructor: (msg)-> @msg = msg} ]
            constructor: -> @_super.constructor(this, "I'm baked")
          )
          instance = new definedObj("I'm baked")
          expect(instance.msg).to.equal("I'm baked")