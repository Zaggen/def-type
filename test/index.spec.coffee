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

  mixin5 =
    enable: true
    preferences:
      fullScreen: true

  mixin6 =
    increaseByOne: (n)->  @sum(n, 1)
    enable: false
    itemList: ['item5']

  describe 'def.Object method define an object that can inherit attributes from multiple mixins (objects/classes)', ->

    describe 'The def-inc module', ->
      it 'should have an Object method', ->
        expect(def.Object).to.exist
        expect(def.Object).to.be.a('function')

      it 'should have a Class method', ->
        expect(def.Class).to.exist
        expect(def.Class).to.be.a('function')

      it 'should have a configure method', ->
        expect(def.settings).to.exist
        expect(def.settings).to.be.a('function')

      describe 'When passing an object to the configure method', ->
        it 'should return the current value of the specified setting', ->
          expect(def.settings('nonEnumOnPrivate')).to.be.true

        it 'should change the current settings of the overriden values', ->
          def.settings({nonEnumOnPrivate: false})
          expect(def.settings('nonEnumOnPrivate')).to.be.false

    describe 'The defined object', ->

      it 'should have all properties from the included mixins', ->
        definedObj = def.Object( include: [mixin1, mixin2, mixin6] )
        expect(definedObj).to.have.all.keys('increaseByOne', 'sum', 'multiply', 'pow', 'enable', 'itemList')

      it 'should be able to call the inherited methods', ->
        definedObj = def.Object( include: [mixin1, mixin2, mixin6])
        expect(definedObj.sum(5, 10)).to.equal(15)
        expect(definedObj.increaseByOne(3)).to.equal(4)
        expect(definedObj.multiply(4, 2)).to.equal(8)
        expect(definedObj.pow(2, 3)).to.equal(9)

      describe 'the inherited attributes(data)', ->
        it 'should have been cloned and not just referenced', ->
          definedObj = def.Object(include: [mixin5, mixin6])
          delete mixin5.preferences.fullScreen
          expect(definedObj.preferences.fullScreen).to.exist

        after ->
          # Lets reset mixin5
          mixin5.preferences = {fullScreen: true}

      describe 'When the included mixins or the currently defined Object/Class has a name conflict on an attribute(data)', ->
        it 'should merge them with the following precedence:
            From left to right in the included mixins list, being the last one the one with more precedence,
            only surpassed by the attribute defined in the current Object/Class itself', ->

          definedObj = def.Object
            include: [mixin5, mixin6]
            increaseByOne: (n)->  @sum(n, 1)
            preferences:
              autoPlay: true

          expect(definedObj.enable).to.be.false
          expect(definedObj.preferences.fullScreen).to.be.true
          expect(definedObj.preferences.autoPlay).to.be.true

      it 'should only include the specified attributes from included, when an attr list [] is provided', ->
        definedObj = def.Object( include: [mixin1, ['sum'], mixin4, ['publicMethod'], mixin6, ['*']] )
        expect(definedObj.sum).to.exist
        expect(definedObj.multiply).to.not.exist
        expect(definedObj._privateAttr).to.not.exist
        expect(definedObj._privateMethod).to.not.exist
        expect(definedObj._privateMethod2).to.not.exist
        expect(definedObj._privateMethod3).to.not.exist

      it 'should be able to exclude an attribute from a baked baseObject, when an "!" flag is provided e.g: ["!", "attr1", "attr2"]', ->
        definedObj = def.Object( include: [mixin1, ['!', 'multiply'], mixin6, ['*'] ] )
        expect(definedObj.sum).to.exist
        expect(definedObj.multiply).to.not.exist


      it 'should include all attributes from a baked baseObject when an ["*"] (includeAll)  flag is provided', ->
        definedObj = def.Object( include: [mixin1, ['*'], mixin6, ['*'] ] )
        expect(definedObj.sum).to.exist
        expect(definedObj.multiply).to.exist
        expect(definedObj.increaseByOne).to.exist

      it 'should exclude all attributes from a baked baseObject when an ["!"] (excludeAll) flag is provided', ->
        definedObj = def.Object( include: [mixin1, ['!'], mixin6, ['*'] ] )
        expect(definedObj.sum).to.not.exist
        expect(definedObj.multiply).to.not.exist
        expect(definedObj.increaseByOne).to.exist

      it 'should have the _.super property hidden and frozen (non: enumerable, configurable, writable)', ->
        definedObj = def.Object( include: [mixin1, mixin6, ['*']])
        expect(definedObj.propertyIsEnumerable('_super')).to.be.false
        expect(Object.isFrozen(definedObj._super)).to.be.true

      it 'should include attributes from constructor functions/classes prototypes, when constructor is excluded', ->
        class Parent
          someMethod: -> 'x'

        definedObj = def.Object( include: [ Parent, ['!', 'constructor'], mixin6, ['*'] ] )
        expect(definedObj.someMethod).to.exist
        expect(definedObj.someMethod()).to.equal('x')

      it 'should throw an error when a constructor method is defined', ->
        defObject = ->
          def.defObject(constructor: -> true)

        expect(defObject).to.throw(Error)

      it 'should not include static attributes (classAttributes) from constructor functions/classes', ->
        class Parent
          @staticMethod: -> 'y'
        definedObj = def.Object( include: [ Parent, ['!', 'constructor'] ])
        expect(definedObj.staticMethod).to.not.exist

      describe 'When the accessors property is defined', ->
        describe 'In the object passed as argument to the def method (Object/Class)', ->
          definedObj = def.Object
            accessors: ['fullName']
            _name: 'John'
            _lastName: 'Doe'
            fullName:
              get: -> "#{@_name} #{@_lastName}"
              set: (fullName)->
                nameParts = fullName.split(' ')
                @_name = nameParts[0]
                @_lastName = nameParts[1]

          it 'should set the getter to the specified attribute', ->
            expect(definedObj.fullName).to.equal('John Doe')

          it 'should set the setter to the specified attribute', ->
            definedObj.fullName
            expect(definedObj.fullName).to.equal('John Doe')

        describe 'In a fn passed as argument to the def method (Object/Class)', ->
          definedObj = def.Object ->
            name = 'John'
            lastName =  'Doe'
            @accessors = ['fullName']
            @fullName =
              get: -> "#{name} #{lastName}"
              set: (fullName)->
                nameParts = fullName.split(' ')
                name = nameParts[0]
                lastName = nameParts[1]

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

          expect(definedObj.privateVar).to.not.exist
          expect(definedObj.get()).to.equal(5)
          definedObj.set(4)
          expect(definedObj.get()).to.equal(4)

        it 'should be able to call truly private methods, when defining it as a local variable of the fn', ->
          definedObj = def.Object ->
            @calculate = (n)-> square(n)
            # Private Methods
            square = (n)-> n * n

          expect(definedObj.calculate(5)).to.equal(25)

      describe 'When an attribute(Only methods) is marked with the ~ flag in the filter array, e.g: ["~methodName"]', ->
        it 'should bind the method context to the original obj (parent) instead of the target obj', ->
          definedObj = def.Object( include: [ mixin4, ['~publicMethod'] ])
          expect(definedObj._privateAttr).to.not.exist
          expect(definedObj._privateMethod).to.not.exist
          expect(definedObj.publicMethod).to.exist
          expect(definedObj.publicMethod(2)).to.equal(10)
        it 'should ignore ~ when using the exclude flag', ->
          definedObj = def.Object( include: [ mixin4, ['!', '~_privateMethod'] ])
          expect(definedObj._privateMethod).to.not.exist

      describe 'When inheriting from multiple objects', ->
        it 'should include/inherit attributes in the opposite order they were passed to the function, so the last ones takes
            precedence over the first ones, when an attribute is found in more than one object', ->

          # This avoids the diamond problem with multiple inheritance
          definedObj = def.Object( include: [ mixin1, {multiply: (x)-> x} ])
          expect(definedObj.multiply(5)).to.equal(5)
          definedObj2 = def.Object( include: [ definedObj, mixin1 ])
          expect(definedObj2.multiply(5, 5)).to.equal(25)

      describe 'When redefining a function in the receiving object', ->
        it 'should be able to call the parent obj method via the _super obj', ->
          definedObj = def.Object
            include: [ mixin1 ]
            multiply: (numbers...)->
              @_super.multiply.apply(this, numbers) * 2

          expect(definedObj.multiply(2, 2)).to.equal(8)

      describe 'When a property is defined with a leading underscore in the passed argument object/fn', ->
        it 'should have that property marked as nonEnumerable', ->
          definedObj = def.Object
            calculation: (x)-> @_pseudoPrivateSquare(x)
            _pseudoPrivateSquare: (x)-> x * x

          expect(Object.keys(definedObj)).to.eql(['calculation'])


    describe 'def.Class method', ->

      it 'should define a js "Class" when a constructor method is defined', ->
        definedClass = def.Class
          constructor:-> true

        expect(definedClass).to.be.a('function')
        expect(new definedClass).to.be.an('object')

      it 'should throw an error when a constructor method is not defined', ->
        defClass = ->
          def.Class(someMethod: -> true)
        expect(defClass).to.throw(Error)

      describe 'When class attributes (static) are defined in a parent class', ->
        it 'should add them to the defined class as static attributes', ->
          class Parent
            @staticMethod: -> 'y'

          definedClass = def.Class
            include: [ Parent, ['!', 'attr'] ]
            constructor:-> true

          expect(definedClass.staticMethod).to.exist
          expect(definedClass.staticMethod()).to.equal('y')

          instanceOfBaked = new definedClass
          expect(instanceOfBaked.staticMethod).to.not.exist

      describe 'When any of the included element defines a constructor method', ->
        it 'should be a constructor function that calls the constructor defined in the receiving obj ', ->
          definedObj = def.Class
            include: [ {constructor: (msg)-> @msg = msg} ]
            constructor: -> @_super.constructor(this, "I'm baked")

          instance = new definedObj("I'm baked")
          expect(instance.msg).to.equal("I'm baked")