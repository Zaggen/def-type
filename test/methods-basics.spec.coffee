describe 'The def-inc module', ->
  it 'should have an Object method', ->
    expect(def.Object).to.exist
    expect(def.Object).to.be.a('function')

  describe 'Module method', ->
    it 'should exist', ->
      expect(def.Module).to.exist
      expect(def.Module).to.be.a('function')

    it 'should be an alias for object method', ->
      expect(def.Module).to.equal(def.Object)

  describe 'Mixin method', ->
    it 'should exist', ->
      expect(def.Mixin).to.exist
      expect(def.Mixin).to.be.a('function')

    it 'should be an alias for object method', ->
      expect(def.Mixin).to.equal(def.Object)

  it 'should have a Class method', ->
    expect(def.Class).to.exist
    expect(def.Class).to.be.a('function')

  it 'should have an Abstract method', ->
    expect(def.Abstract).to.exist
    expect(def.Abstract).to.be.a('function')

  it 'should have a setNonEnum method', ->
    expect(def.setNonEnum).to.exist
    expect(def.setNonEnum).to.be.a('function')

  it 'should have a getNonEnum method', ->
    expect(def.getNonEnum).to.exist
    expect(def.getNonEnum).to.be.a('function')

  describe 'getEnum method', ->
    it 'should return the nonEnum settings', ->
      settings = def.getNonEnum()
      expect(settings.leadingChar).to.equal('_')
      expect(settings.enabled).to.be.a('boolean')

  describe 'setEnum method', ->
    describe 'when the only the first argument is passed', ->
      it 'should set the leadingChar to whatever is passed as the first argument and the enabled status as true',->
        def.setNonEnum('_')
        expect(def.getNonEnum().leadingChar).to.equal('_')
        expect(def.getNonEnum().enabled).to.be.true

    describe 'when the two arguments are passed', ->
      it 'should set the first argument as the leading char and the second as the enabled status',->
        def.setNonEnum('$', false)
        expect(def.getNonEnum().leadingChar).to.equal('$')
        expect(def.getNonEnum().enabled).to.be.false

    after ->
      def.setNonEnum('_', false)