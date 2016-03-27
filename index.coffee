_ = require('lodash')
filter = require('./properties-filter')

#helpers
log = console.log

# Module Vars
defInc = {}
options = null # []
mixins = null # []
definedAttrs = null # {}
currentNonEnumConf = null # {}
staticMethods = null # {}
parentPrototype = null # {}
useParentContext = null # {}
conf =
  nonEnum:
    leadingChar: '_'
    enabled: false

defInc =
  defObject: (propsDefiner)->
    defInc.define(propsDefiner, 'object')

  defClass: (propsDefiner)->
    defInc.define(propsDefiner, 'class')

  defAbstract: (propsDefiner)->
    if propsDefiner.hasOwnProperty('constructor')
      defInc.define(propsDefiner, 'class')
    else
      defInc.define(propsDefiner, 'object')

  ###*
  * Defines a new Object or a Class that can inherit properties from other objects/classes in
  * a composable way, i.e you can pick, omit and delegate(methods) from the parent objects.
  * @param {object|function} propsDefiner
  * @param {string} type
  * @return {object|function}
  ###
  define: (propsDefiner, type = 'object')->
    definedObj = @setObj(propsDefiner, type)
    for mixin, i in mixins
      filter.set(options[i])
      # Checks each property and compares it against the defined (or default) filters
      # and when they are not skipped by the filter it adds them to the defined object

      propertyNames = Object.getOwnPropertyNames(mixin)
      for propertyName in propertyNames
        unless filter.skip(propertyName)
          property = mixin[propertyName]
          if _.isFunction(property)
            @addMethod(definedObj, propertyName, property, mixin, type)
          else
            @addAttribute(definedObj, propertyName, property) if propertyName isnt '_super'

      # Once we are done with all attributes, we check for any static property
      # to add to our static properties object
      if mixin.__static__? then @pushStaticMethods(mixin)

    @markPropertiesAsNonEnum(definedObj) if conf.nonEnum or currentNonEnumConf
    @freezeProp(definedObj, '_super')

    # Returns a pseudo-class or the currently defined object
    type = @makeType(definedObj, type)
    @clearData()
    return type

  ###* @private ###
  setObj: (propsDefiner, type)->
    definedObj = {}
    if _.isFunction(propsDefiner)
      propsDefiner.call(definedObj)
    else
      definedObj = propsDefiner

    includedTypes = definedObj.merges
    parent = definedObj.extends
    prototype = if parent?.prototype? then parent.prototype else parent
    accessors = definedObj.accessors
    currentNonEnumConf = @makeNonEnumSettings.apply(@, definedObj.nonEnum)
    @checkIfValid(definedObj, type)
    @defineAccessors(definedObj, accessors) if accessors?

    # Filter(separates) parentObjects/classes from configurations arrays
    @setIncludes(includedTypes)

    definedObj = @clearConfigKeys(definedObj)
    definedAttrs = _.mapValues(definedObj, (val)-> true) # Creates an obj, with the newObj keys, and a boolean
    staticMethods = {}

    # If the defined object/class extends another object/class
    if parent?
      objWithProto = Object.create(prototype)
      definedObj = _.merge(objWithProto, definedObj)
      definedObj._super = {constructor: prototype.constructor }
    else
      definedObj._super = {}

    return definedObj

  ###* @private ###
  clearConfigKeys: (definedObj)->
    tempObj = {}
    reservedKeys = ['merges', 'extends', 'accessors', 'nonEnum']
    for key, attr of definedObj
      unless _.includes(reservedKeys, key)
        tempObj[key] = attr
    return tempObj

  ###* @private ###
  addMethod: (definedObj, key, attr, mixin)->
    fn = attr
    fn = if useParentContext.hasOwnProperty(key) then fn.bind(mixin) else fn

    if definedAttrs.hasOwnProperty(key)
      definedObj._super[key] = fn unless key is 'constructor'
    else
      # If method is not found at the defined object, we
      # still store that method in the _super obj to allow
      # access to it, in case the method is overridden in the
      # defined obj at a later time in runtime.
      definedObj[key] = definedObj._super[key] = fn

  ###* @private ###
  addAttribute: (definedObj, key, value)->
    # We check if the receiving object already has an attribute with that keyName
    # if none is found or the attr is an array/obj we concat/merge it
    if definedAttrs.hasOwnProperty(key)
      if _.isObject(value) and not _.isArray(value)
        definedObj[key] = _.merge({}, value, definedObj[key])
        return true
    else
      definedObj[key] = _.cloneDeep(value)
      return true
    return false

  ###*
  * Checks if the object that is supposed to be a class has a constructor, and
  * that the one that is supposed to be a plainObject does not have one.
  * @private
  ###
  checkIfValid: (obj, type)->
    hasConstructor = obj.hasOwnProperty('constructor')
    if type is 'object' and hasConstructor
      msg = '''
            Constructor is a reserved keyword, to define classes
            when using def.Class method, but you are
            defining an object
            '''

      throw new Error msg
    else if type is 'class' and not hasConstructor
      msg = 'No constructor defined in the object. To create a class, a constructor must be defined as a key'
      throw new Error msg

  ###* @private ###
  defineAccessors: (obj, accessorsList)->
    for propertyName in accessorsList
      Object.defineProperty(obj, propertyName, obj[propertyName])

  # Filters from the arguments the base objects/classes and the option filter arrays
  ###* @private ###
  setIncludes: (mixinList)->
    mixins = []
    options = []
    useParentContext = {}
    balancer =
      mixinsCount: 0
      optionsCount: 0
    # definedObj = def.Object( merges: [mixin1, ['sum'], mixin4, ['publicMethod'], mixin6, ['*']] )
    _.each mixinList, (mixin)=>
      if not _.isObject(mixin)
        throw new Error 'Def-inc only accepts objects/arrays/fns e.g (fn/{} parent objects/classes or an [] with options)'
      else if @isOptionArr(mixin)
        # We check if the is other options already set for the mixins, by checking the difference
        # between the mixinCount and the optionsCount, and we add the include all flag in an array ['*']
        # before adding the actual option into the options array
        balancer.optionsCount++
        padding = balancer.mixinsCount - balancer.optionsCount
        for i in [0...padding]
          options.push(@makeOptionsObj(['*']))

        options.push(@makeOptionsObj(mixin))

      else if _.isFunction(mixin)
        # When a fn is passed, we assume is a constructor, so we copy the properties in its prototype,
        # as well as any attribute that might be attached to the constructor itself(not usual, but lets be safe)
        # to an empty object. Then we add a constructor property to this new obj, so inheriting from "classes", will
        # always result in objects with constructors as one of their keys, unless is specifically excluded by the caller.
        fn = mixin
        #obj = _.merge({}, fn, fn::)
        obj = _.merge({}, fn::)
        obj.constructor = fn
        Object.defineProperty obj,
          '__static__',
          value: _.merge({}, fn)
          enumerable: false
        mixins.push(obj)
        balancer.mixinsCount++
      else
        # If it is a simple object we just add it to our array
        mixins.push(mixin)
        balancer.mixinsCount++

  ###* @private ###
  isOptionArr: (arg)->
    if _.isArray arg
      isStringsArray = _.every(arg, (item)-> if _.isString item then true else false)
      if isStringsArray
        return true
      else
        throw new Error 'Array contains illegal types: The config [] should only contain strings i.e: (attr names or filter symbols (! or *) )'
    else
      return false

  ###* @private ###
  makeOptionsObj: (attrNames)->
    filterKey = attrNames[0]
    switch filterKey
      when '!'
        if attrNames[1]?
          attrNames.shift()
          attrNames = @filterParentContextFlag(attrNames,true) # We use this one here just to make sure somebody didn't call
          return {'exclude': attrNames}
        else
          return {'excludeAll': true}
      when '*'
        return {'includeAll': true}
      else
        attrNames = @filterParentContextFlag(attrNames)
        return {'include': attrNames}

  # Checks for ~ flag in each attribute name... e.g ['~methodName'], even though we check this for all
  # attributes in the list, it will only work when including method names. It won't work with excludes,
  # regular attributes
  ###* @private ###
  filterParentContextFlag: (attrNames, warningOnMatch)->
    newAttrNames = []
    for attrName in attrNames
      if attrName.charAt(0) is '~'
        if warningOnMatch
          console.warn 'The ~ should only be used when including methods, not excluding them'
        attrName = attrName.replace('~', '')
        newAttrNames.push(attrName)
        useParentContext[attrName] = true
      else
        newAttrNames.push(attrName)
    return newAttrNames

  ###*
  @private
  ###
  checkForBalance: (mixins, options)->
    if options.length > 0 and mixins.length isnt options.length
      throw new Error 'Invalid number of conf-options: If you provide a conf obj, you must provide one for each mixin'
    return true

  ###* @private ###
  pushStaticMethods: (mixin)->
    for own key, attr of mixin.__static__
      unless filter.skip(key)
        staticMethods[key] = attr

  markPropertiesAsNonEnum: (definedObj)->
    nonEnum = currentNonEnumConf
    if nonEnum.enabled
      propertyNames = Object.getOwnPropertyNames(definedObj)
      for propertyName in propertyNames
        if propertyName.charAt(0) is nonEnum.leadingChar
          @defNonEnumProp(definedObj, propertyName)

    return true

  ###* @private ###
  makeNonEnumSettings: ->
    if arguments[0]?
      leadingChar = arguments[0]
      enabledStatus = if arguments[1]? then arguments[1] else true # The default might have changed so we make sure is true
      return {
        nonEnum:
          leadingChar: leadingChar
          enabled: enabledStatus
      }
    else
      return conf.nonEnum

  ###* @private ###
  freezeProp: (obj, attributeName)->
    if obj[attributeName]?
      Object.freeze obj[attributeName]

  ###* @private ###
  defNonEnumProp: (obj, attributeName)->
    if obj[attributeName]?
      Object.defineProperty obj, attributeName, {enumerable: false}

  ###*
  * Makes a pseudoClass (Constructor) and returns it when type is 'class' or
  * it returns the currently defined object as it is (when type is 'object')
  * @private
  ###
  makeType: (definedObj, type)->
    if type is 'class' then @makeConstructor(definedObj) else definedObj

  ###* @private ###
  makeConstructor: (classPrototype)->
    classFn = classPrototype.constructor
    classFn:: = classPrototype
    if parentPrototype?
      classFn:: = Object.create(parentPrototype)
      classFn:: = _.merge(classFn.prototype, classPrototype)
      classFn::_super = classPrototype._super

    if staticMethods?
      _.merge(classFn, staticMethods)

    return classFn

  clearData: ->
    # Module Vars
    options = null # []
    mixins = null # []
    definedAttrs = null # {}
    currentNonEnumConf = null # {}
    staticMethods = null # {}
    useParentContext = null # {}

module.exports =
  Class: defInc.defClass
  Abstract: defInc.defAbstract
  Object: defInc.defObject
  # Alias for Object definition, just syntactic sugar
  Module: defInc.defObject
  Mixin: defInc.defObject

  # Shortcuts for nonEnum
  setNonEnum: ->
    conf = defInc.makeNonEnumSettings(arguments[0], arguments[1])

  getNonEnum: ->
    conf.nonEnum
