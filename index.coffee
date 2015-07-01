_= require('lodash')

defIncModule =
  ###*
  * Defines a new Object or a Class that can inherit properties from other objects/classes in
  * a composable way, i.e you can pick, omit and delegate(methods) from the parent objects.
  * @param {object|function} propsDefiner
  * @param {string} type
  * @return {object|function}
  ###
  define: (propsDefiner, type = 'object')->
    definedObj = @setObj(propsDefiner, type)

    for baseObj, i in @baseObjs
      @filter.set(@options[i])
      # Checks each propertie and compares it against the defined (or default) filters
      # and when they are not skipped by the filter it adds them to the defined object
      for own key, attr of baseObj
        unless @filter.skip(key)
          if _.isFunction(attr)
            @addMethod(definedObj, key, attr, baseObj)
          else
            @addAttribute(definedObj, key, attr)

      # Once we are done with all attributes, we check for any static property
      # to add to our static properties object
      if baseObj.__static__? then @pushStaticMethods(baseObj)

    @freezeAndHideAttr(definedObj, '_super')

    # Returns a pseudo-class or the currently defined object
    return @makeType(definedObj, type)

  ###* @private ###
  setObj: (propsDefiner, type)->
    definedObj = {}
    if _.isFunction(propsDefiner)
      propsDefiner.call(definedObj)
    else
      definedObj = propsDefiner

    includedTypes = definedObj.include
    #prototype = definedObj.prototype # Not used yet
    accessors = definedObj.accessors

    @checkIfValid(definedObj, type)
    @defineAccessors(definedObj, accessors) if accessors?

    # Filter(separates) parentObjects/classes from configurations arrays
    @filterArgs(includedTypes)
    definedObj = @clearConfigKeys(definedObj)
    @definedAttrs = _.mapValues(definedObj, (val)-> true) # Creates an obj, with the newObj keys, and a boolean
    @staticMethods = {}

    return definedObj

  ###* @private ###
  clearConfigKeys: (definedObj)->
    tempObj = {}
    reservedKeys = ['include', 'prototype', 'accessors']
    for key, attr of definedObj
      unless _.contains(reservedKeys, key)
        tempObj[key] = attr

    tempObj._super = {}
    return tempObj

  ###* @private ###
  addMethod: (definedObj, key, attr, baseObj)->
    fn = attr
    fn = if @useParentContext.hasOwnProperty(key) then fn.bind(baseObj) else fn
    if @definedAttrs.hasOwnProperty(key)
      if key is 'constructor'
        @setSuperConstructor(definedObj, fn)
      else
        definedObj._super[key] = fn
    else
      definedObj[key] = definedObj._super[key] = fn

  ###* @private ###
  addAttribute: (definedObj, key, attr)->
    # We check if the receiving object already has an attribute with that keyName
    # if none is found or the attr is an array/obj we concat/merge it
    if not @definedAttrs.hasOwnProperty(key)
      definedObj[key] = _.cloneDeep(attr)
    else if _.isArray(attr)
      definedObj[key] = definedObj[key].concat(attr)
    else if _.isObject(attr) and key isnt '_super'
      definedObj[key] = _.merge(definedObj[key], attr)

  ###*
  * Checks if the object that is supposed to be a class has a constructor, and
  * that the one that is supposed to be a plainObject does not have one.
  * @private
  ###
  checkIfValid: (obj, type)->
    hasConstructor = obj.hasOwnProperty('constructor')
    if type is 'object' and  hasConstructor
      msg = '''
            Constructor is a reserved keyword, to define classes
            when using def.Class method, but you are
            defining an object
            '''
      throw new Error msg
    else if type is 'class' and not hasConstructor
      msg 'No constructor defined in the object. To create a class a constructor must be defined as a key'
      throw new Error msg

  ###* @private ###
  defineAccessors: (obj, accessorsList)->
    for propertyName in accessorsList
      Object.defineProperty(obj, propertyName, obj[propertyName])

  ###*
  * @TODO Needs to support multiple constructor calling
  * @private
  ###
  setSuperConstructor: (target, constructor)->
    target._super.constructor = (superArgs...)-> constructor.apply(superArgs.shift(), superArgs)

  # Filters from the arguments the base objects/classes and the option filter arrays
  ###* @private ###
  filterArgs: (args)->
    @baseObjs = []
    @options = []
    @useParentContext = {}
    _.each args, (arg)=>
      if not _.isObject(arg)
        throw new Error 'BakeIn only accepts objects/arrays/fns e.g (fn/{} parent objects/classes or an [] with options)'
      else if @isOptionArr(arg)
        @options.push(@makeOptionsObj(arg))
      else if _.isFunction(arg)
        # When a fn is passed, we assume is a constructor, so we copy the properties in its prototype,
        # as well as any attribute that might be attached to the constructor itself(not usual, but lets be safe)
        # to an empty object. Then we add a constructor property to this new obj, so inheriting from "classes", will
        # always result in objects with constructors as one of their keys, unless is specifically excluded by the caller.
        fn = arg
        #obj = _.merge({}, fn, fn::)
        obj = _.merge({}, fn::)
        obj.constructor = fn
        Object.defineProperty obj,
          '__static__',
          value: _.merge({}, fn)
          enumerable: false

        @baseObjs.push(obj)
      else
        # If it is a simple object we just add it to our array
        @baseObjs.push(arg)

  ###* @private ###
  isOptionArr: (arg)->
    if _.isArray arg
      isStringsArray =  _.every( arg, (item)-> if _.isString item then true else false )
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
          attrNames = @filterParentContextFlag(attrNames, true) # We use this one here just to make sure somebody didn't call
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
        @useParentContext[attrName] = true
      else
        newAttrNames.push(attrName)
    return newAttrNames

  ###*
  @private
  ###
  checkForBalance: (baseObjs, options)->
    if options.length > 0 and baseObjs.length isnt options.length
      throw new Error 'Invalid number of conf-options: If you provide a conf obj, you must provide one for each baseObj'
    return true

  ###*
  * Helper obj to let us know if we should skip, based on
  * the filter provided and the current key.
  * @private
  ###
  filter:
    set: (conf)->
      if conf?
        @mode = _.keys(conf)[0]
        @attrFilters = conf[@mode]
        # If an string was provided instead of an array (intentionally or unintentionally) we convert it to an array
        if _.isString(@attrFilters)
          @attrFilters = @attrFilters.split(',')
      else
        @mode = undefined
        @attrFilters = undefined


    skip: (key)->
      # When a certain condition is met, will return true or false, so the caller can
      # know if it should skip or not
      switch @mode
        when 'include'
          # When there are no items left on the included list, we return true to always skip
          if @attrFilters.length is 0
            return true

          keyIndex = _.indexOf(@attrFilters, key)
          # If we find the key to be included we don't skip so we return false, and we remove it from the list
          if keyIndex >= 0
            _.pullAt(@attrFilters, keyIndex)
            return false
          else
            return true

        when 'exclude'
          # When there are no items left on the excluded list, we return false to avoid skipping
          if @attrFilters.length is 0
            return false

          keyIndex = _.indexOf(@attrFilters, key)
          # If we find the key to be excluded we want to skip so we return true, and we remove it from the list
          if keyIndex >= 0
            _.pullAt(@attrFilters, keyIndex)
            return true
          else
            return false

        when 'includeAll'
          # We never skip
          return false

        when 'excludeAll'
          # We always skip - Useful to quickly disable inheritance in dev env
          return true
        else
          # When no options provided is the same as include all, so we never skip
          return false

  ###* @private ###
  pushStaticMethods: (baseObj)->
    for own key, attr of baseObj.__static__
      unless @filter.skip(key)
        @staticMethods[key] = attr

  ###* @private ###
  freezeAndHideAttr: (obj, attributeName)->
    if obj[attributeName]?
      Object.defineProperty obj, attributeName, {enumerable: false}
      Object.freeze obj[attributeName]

  ###*
  * Makes a pseudoClass (Constructor) and returns it when type is 'class' or
  * it returns the currently defined object as it is (when type is 'object')
  * @private
  ###
  makeType: (definedObj, type)->
    if type is 'class' then @makeConstructor(definedObj) else definedObj

  ###* @private ###
  makeConstructor: (obj)->
    classFn = obj.constructor
    _.merge(classFn, @staticMethods)
    classFn.prototype = obj
    #fn.prototype.constructor = fn # This creates a circular reference, should check soon
    return classFn

module.exports =
  Object: (obj)->
    defIncModule.define.call(defIncModule, obj, 'object')
  Class: (obj)->
    defIncModule.define.call(defIncModule, obj, 'class')