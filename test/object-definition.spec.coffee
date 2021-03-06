describe 'def.Object method', ->
  describe 'The defined object', ->
    describe 'When using the "extends" directive', ->
      it 'should have all properties from the passed mixin via prototype', ->
        definedObj = def.Object(extends: mixin1)
        expect(definedObj.__proto__).to.have.all.keys('sum', 'multiply')

      it 'should have all properties from the passed Class prototype without specifying', ->
        class User
          constructor: (@name)->
          getName: -> @name

        writer = def.Object
          extends: User
          name: 'Jake'
          write: ->

        expect(writer.getName).to.exist
        expect(writer.getName()).to.equal('Jake')
        expect(writer.write).to.exist

    describe 'When using the "merges" directive', ->
      it 'should have all properties from the included (merged) mixins', ->
        definedObj = def.Object(merges: [mixin1, mixin2, mixin6])
        expect(definedObj).to.have.all.keys('_super', 'increaseByOne', 'sum', 'multiply', 'pow', 'enable', 'itemList')

      it 'should be able to call the inherited methods', ->
        definedObj = def.Object(merges: [mixin1, mixin2, mixin6])
        expect(definedObj.sum(5, 10)).to.equal(15)
        expect(definedObj.increaseByOne(3)).to.equal(4)
        expect(definedObj.multiply(4, 2)).to.equal(8)
        expect(definedObj.pow(2, 3)).to.equal(9)

      describe 'the inherited attributes(data)', ->
        it 'should have been cloned and not just referenced', ->
          definedObj = def.Object(merges: [mixin5, mixin6])
          delete mixin5.preferences.fullScreen
          expect(definedObj.preferences.fullScreen).to.exist

        after ->
          # Lets reset mixin5
          mixin5.preferences = {fullScreen: true}

      describe 'When the merged mixins or the currently defined Object/Class has a name conflict on an attribute(data)', ->
        it 'should merge them with the following precedence:
                From left to right in the merges mixins list, being the last one the one with more precedence,
                only surpassed by the attribute defined in the current Object/Class itself', ->
          definedObj = def.Object
            merges: [mixin5, mixin6]
            increaseByOne: (n)-> @sum(n, 1)
            preferences:
              autoPlay: true
              muted: true
            favoriteChannels: [31, 23]

          expect(definedObj.enable).to.be.false
          expect(definedObj.preferences.fullScreen).to.be.true
          expect(definedObj.preferences.autoPlay).to.be.true
          expect(definedObj.preferences.muted).to.be.true
          expect(definedObj.favoriteChannels).to.eql([31, 23])

      it 'should only include the specified attributes from the merged obj/class, when an attr list [] is provided', ->
        definedObj = def.Object(merges: [mixin1, ['sum'], mixin4, ['publicMethod'], mixin6])
        expect(definedObj.sum).to.exist
        expect(definedObj.multiply).to.not.exist
        expect(definedObj._privateAttr).to.not.exist
        expect(definedObj._privateMethod).to.not.exist
        expect(definedObj._privateMethod2).to.not.exist
        expect(definedObj._privateMethod3).to.not.exist

      it 'should be able to exclude an attribute from merged mixin/Class, when an "!" flag is provided e.g: ["!", "attr1", "attr2"]', ->
        definedObj = def.Object(merges: [mixin1, ['!', 'multiply'], mixin6, ['*']])
        expect(definedObj.sum).to.exist
        expect(definedObj.multiply).to.not.exist


      it 'should include all attributes from a merged mixin when an ["*"] (includeAll)  flag is provided', ->
        definedObj = def.Object(merges: [mixin1, ['*'], mixin6, ['*']])
        expect(definedObj.sum).to.exist
        expect(definedObj.multiply).to.exist
        expect(definedObj.increaseByOne).to.exist

      it 'should exclude all attributes from a merged mixin when an ["!"] (excludeAll) flag is provided', ->
        definedObj = def.Object(merges: [mixin1, ['!'], mixin6, ['*']])
        expect(definedObj.sum).to.not.exist
        expect(definedObj.multiply).to.not.exist
        expect(definedObj.increaseByOne).to.exist

      describe 'When merging multiple objects and not passing merging options to all of them', ->
        it 'should assume an "*" flag for those that are not explicitly defined', ->
          definedObj = def.Object(merges: [mixin1, mixin6, ['increaseByOne']])
          expect(definedObj.increaseByOne(4)).to.equal(5)
          expect(definedObj.multiply).to.exist

          # Different order
          definedObj2 = def.Object(merges: [mixin1, ['sum'], mixin6])
          expect(definedObj2.increaseByOne(4)).to.equal(5)
          expect(definedObj2.multiply).to.not.exist

      it 'should include attributes from constructor functions/classes prototypes, when constructor is excluded', ->
        class Parent
          someMethod: -> 'x'

        definedObj = def.Object(merges: [Parent, ['!', 'constructor'], mixin6, ['*']])
        expect(definedObj.someMethod).to.exist
        expect(definedObj.someMethod()).to.equal('x')

      it 'should throw an error when a constructor method is defined', ->
        defObject = ->
          def.defObject(constructor: -> true)

        expect(defObject).to.throw(Error)

      it 'should not include static attributes (classAttributes) from constructor functions/classes', ->
        class Parent
          @staticMethod: -> 'y'
        definedObj = def.Object(merges: [Parent, ['!', 'constructor']])
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
            lastName = 'Doe'
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
          definedObj = def.Object(merges: [mixin4, ['~publicMethod']])
          expect(definedObj._privateAttr).to.not.exist
          expect(definedObj._privateMethod).to.not.exist
          expect(definedObj.publicMethod).to.exist
          expect(definedObj.publicMethod(2)).to.equal(10)
        it 'should ignore ~ when using the exclude flag', ->
          definedObj = def.Object(merges: [mixin4, ['!', '~_privateMethod']])
          expect(definedObj._privateMethod).to.not.exist

      describe 'When inheriting from multiple objects', ->
        it 'should include/inherit attributes in the opposite order they were passed to the function, so the last ones takes
                precedence over the first ones, when an attribute is found in more than one object', ->

          # This avoids the diamond problem with multiple inheritance
          definedObj = def.Object(merges: [mixin1, {multiply: (x)-> x}])
          expect(definedObj.multiply(5)).to.equal(5)
          definedObj2 = def.Object(merges: [definedObj, mixin1])
          expect(definedObj2.multiply(5, 5)).to.equal(25)

      #TODO: Improve readability of these specs
      describe 'When overriding a method in the defined object', ->
        definedObj = def.Object
          merges: [mixin1]
          multiply: (numbers...)->
            @_super.multiply.apply(@, numbers) * 2

        describe 'The _super object', ->
          describe 'When the defined object merges in an object literal (vanilla js)', ->
            it 'should have all methods from the parent, overridden or not', ->
              expect(Object.keys(definedObj._super)).to.eql(['sum', 'multiply'])

          describe 'When the defined object merges in an object defined via def-type module', ->
            definedMixin = def.Object
              sum: (numbers...)->
                r = 0
                r += n for n in numbers
                return r

            definedObj2 = def.Object
              merges: [definedMixin]
              multiply: (numbers...)->
                definedObj2._super.multiply.apply(@, numbers) * 2

            it 'should have all methods from the parent, overridden or not', ->
              expect(Object.keys(definedObj2._super)).to.eql(['sum'])

        it 'should be able to call the parent obj method via the _super obj', ->
          expect(definedObj.multiply(2, 2)).to.equal(8)

      describe 'When a property is defined with a leading underscore in the passed argument object/fn', ->
        it 'should have that property marked as nonEnumerable', ->
          def.setNonEnum('_', true)
          definedObj = def.Object
            calculation: (x)-> @_pseudoPrivateSquare(x)
            _pseudoPrivateSquare: (x)-> x * x

          expect(Object.keys(definedObj)).to.eql(['calculation'])

        it 'should not have that property marked as nonEnumerable if the "nonEnumOnPrivate" setting is turned off globally', ->
          def.setNonEnum('_', false)
          definedObj = def.Object
            calculation: (x)-> @_pseudoPrivateSquare(x)
            _pseudoPrivateSquare: (x)-> x * x

          expect(Object.keys(definedObj)).to.eql(['calculation', '_pseudoPrivateSquare', '_super'])
          def.setNonEnum('_', true)

        it 'should not have that property marked as nonEnumerable if the "nonEnumOnPrivate" setting is turned off locally', ->
          definedObj = def.Object
            nonEnum: ['_', false]
            calculation: (x)-> @_pseudoPrivateSquare(x)
            _pseudoPrivateSquare: (x)-> x * x

          expect(Object.keys(definedObj)).to.eql(['calculation', '_pseudoPrivateSquare', '_super'])