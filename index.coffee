_= require('lodash')

# Takes 0 or more objects to extend/enhance a target object with their attributes.
# Lets you set which attributes to inherit, by passing an array for each object to inherit:
# - You can pass lets say 3 objects, and then 3 config arrays like this:
#   bakeIn(obj1, obj2, obj3, ['attr1'], ['*'], ['!', 'attr2'], targetObj), or you can pass it like this:
#   bakeIn(obj1, ['attr1'], obj2, ['*'], obj3, ['attr2'], targetObj), it doesn't matter if you mix them up,
#   but the order and quantity of conf arrays must match the order and quantity of parentObjects.
defIncModule =
  def: (obj, type = 'object')->
    obj = if _.isFunction(obj) then new obj else obj
    includedTypes = obj.include_
    prototype = obj.prototype_
    privatizedObj = obj.privatize_
    newObj = {}
    newObj._super = {}
    newObjAtrrs = _.mapValues(obj, (val)-> true) # Creates an obj, with the newObj keys, and a boolean
    # Filter(separates) parentObjects/classes from configurations arrays

    ###@_checkIfValid(obj, type)###

    if  _.size(privatizedObj) > 0
      newObj = privatizedObj
    else
      reservedKeys = ['include_', 'prototype_', 'privatize_']
      for key, attr of obj
        unless _.contains(reservedKeys, key)
          newObj[key] = attr


    @_filterArgs(includedTypes)
    @staticMethods = {}

    for baseObj, i in @baseObjs
      @_filter.set(@options[i])
      for own key, attr of baseObj
        unless @_filter.skip(key)
          if _.isFunction(attr)
            fn = attr
            fn = if @useParentContext.hasOwnProperty(key) then fn.bind(baseObj) else fn
            if newObjAtrrs.hasOwnProperty(key)
              if key is 'constructor'
                @_setSuperConstructor(newObj, fn)
              else
                newObj._super[key] = fn
            else
              newObj[key] = newObj._super[key] = fn
          else
            # We check if the receiving object already has an attribute with that keyName
            # if none is found or the attr is an array/obj we concat/merge it
            if not newObjAtrrs.hasOwnProperty(key)
              newObj[key] = _.cloneDeep(attr)
            else if _.isArray(attr)
              newObj[key] = newObj[key].concat(attr)
            else if _.isObject(attr) and key isnt '_super'
              newObj[key] = _.merge(newObj[key], attr)

    @_freezeAndHideAttr(newObj, '_super')
    if type is 'class'
      return @_makeConstructor(newObj)
    else
      return newObj

  _checkIfValid: (obj, type)->
    hasConstructor = obj.hasOwnProperty('constructor')

    if type is 'object' and  hasConstructor
      msg = '''
            Constructor is a reserved keyword, to define classes
            when using def.Class method, but you are
            defining an object
            '''
      throw new Error msg
    else if type is 'class' and hasConstructor
      msg 'No constructor defined in the object. To create a class a constructor must be defined as a key'
      throw new Error msg

  _setSuperConstructor: (target, constructor)->
    target._super.constructor = (superArgs...)-> constructor.apply(superArgs.shift(), superArgs)

  # Filters from the arguments the base objects/classes and the option filter arrays
  _filterArgs: (args)->
    @baseObjs = []
    @options = []
    @useParentContext = {}
    _.each args, (arg)=>
      if not _.isObject(arg)
        throw new Error 'BakeIn only accepts objects/arrays/fns e.g (fn/{} parent objects/classes or an [] with options)'
      else if @_isOptionArr(arg)
        @options.push(@_makeOptionsObj(arg))
      else if _.isFunction(arg)
        # When a fn is passed, we assume is a constructor, so we copy the properties in its prototype,
        # as well as any attribute that might be attached to the constructor itself(not usual, but lets be safe)
        # to an empty object. Then we add a constructor property to this new obj, so inheriting from "classes", will
        # always result in objects with constructors as one of their keys, unless is specifically excluded by the caller.
        fn = arg
        obj = _.merge({}, fn, fn::)
        obj.constructor = fn
        @baseObjs.push(obj)
      else
        # If it is a simple object we just add it to our array
        @baseObjs.push(arg)


  _isOptionArr: (arg)->
    if _.isArray arg
      isStringsArray =  _.every( arg, (item)-> if _.isString item then true else false )
      if isStringsArray
        return true
      else
        throw new Error 'Array contains illegal types: The config [] should only contain strings i.e: (attr names or filter symbols (! or *) )'
    else
      return false

  _makeOptionsObj: (attrNames)->
    filterKey = attrNames[0]
    switch filterKey
      when '!'
        if attrNames[1]?
          attrNames.shift()
          attrNames = @_filterParentContextFlag(attrNames, true) # We use this one here just to make sure somebody didn't call
          return {'exclude': attrNames}
        else
          return {'excludeAll': true}
      when '*'
        return {'includeAll': true}
      else
        attrNames = @_filterParentContextFlag(attrNames)
        return {'include': attrNames}

  # Checks for ~ flag in each attribute name... e.g ['~methodName'], even though we check this for all
  # attributes in the list, it will only work when including method names. It won't work with excludes,
  # regular attributes
  _filterParentContextFlag: (attrNames, warningOnMatch)->
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

  _checkForBalance: (baseObjs, options)->
    if options.length > 0 and baseObjs.length isnt options.length
      throw new Error 'Invalid number of conf-options: If you provide a conf obj, you must provide one for each baseObj'
    return true

  # Helper obj to let us know if we should skip, based on
  # the bakeIn filter provided and the current key
  _filter:
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

  _freezeAndHideAttr: (obj, attributeName)->
    if obj[attributeName]?
      Object.defineProperty obj, attributeName, {enumerable: false}
      Object.freeze obj[attributeName]

  _makeConstructor: (obj)->
    fn = (args...)->
      obj.constructor.apply(this, args)
    fn.prototype = obj
    #fn.prototype.constructor = fn # This creates a circular reference, should check soon

    #console.log 'fn', fn.prototype
    return fn

module.exports = {
  Object: (obj)->
    defIncModule.def.call(defIncModule, obj, 'object')
  Class: (obj)->
    defIncModule.def.call(defIncModule, obj, 'class')
}