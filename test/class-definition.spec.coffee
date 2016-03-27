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

  describe 'When using the "merges" directive', ->

    describe 'When class attributes (static) are defined in a parent class', ->
      it 'should add them to the defined class as static attributes', ->
        class Parent
          @staticMethod: -> 'y'

        definedClass = def.Class
          merges: [ Parent, ['!', 'attr'] ]
          constructor:-> true

        expect(definedClass.staticMethod).to.exist
        expect(definedClass.staticMethod()).to.equal('y')

        instanceOfBaked = new definedClass
        expect(instanceOfBaked.staticMethod).to.not.exist

    describe 'When any of the merged element defines a constructor method', ->
      describe 'it should not be available via @_super fn call', ->
        superClass = def.Class
          constructor: (msg)-> @msg = msg

        definedClass = def.Class
          merges: [superClass]
          constructor: ->
            superClass.call(this, "I'm baked")

        instance = new definedClass("I'm baked")
        expect(instance.msg).to.equal("I'm baked")
        expect(instance._super).to.be.an("object")

  describe 'When using the "extends" directive', ->

    User = def.Class
      constructor: (name)->
        @userName = name
      getName: ->
        return @userName

    describe 'When defining a class', ->
      Admin = def.Class
        extends: User
        constructor: (name, @clearanceLvl)->
          @_super.constructor.call(@, name)

        someMethod: ->
          @getName()

      userName = 'zaggen'

      it 'should have all properties from the passed Class', ->
        expect(Admin.prototype.__proto__).to.have.all.keys('constructor', 'getName', '_super')

      it 'should have access to the parent Class constructor via the @_super fn', ->
        adminUser = new Admin(userName, 5)
        expect(adminUser._super).to.be.an('object')
        expect(adminUser.userName).to.equal(userName)
        expect(adminUser.someMethod()).to.equal(userName)

      it 'should have access to the parent Class methods via the @_super obj', ->
        adminUser = new Admin(userName, 5)
        expect(adminUser.someMethod()).to.equal(userName)

  describe 'def.Abstract method', ->
    it 'should define an object, just as def.object method when no constructor is defined', ->
      abstractObj = def.Abstract
        someMethod: -> true
      expect(abstractObj).to.be.an('object')
      expect(abstractObj.someMethod).to.exist

    it 'should define a Class when the constructor is defined', ->
      abstractClass = def.Abstract
        constructor: -> @_x = 5
        someMethod: -> true

      expect(abstractClass).to.be.a('function')

    it 'should define a Class that can be used to extend classes and objects', ->

      AbstractClass = def.Abstract
        constructor: -> @_x = 5
        someMethod: -> true

      concreteClass = def.Class
        extends: AbstractClass
        constructor: ->
          @_x = @_super.constructor()

      instance = new concreteClass
      expect(instance._x).to.exist