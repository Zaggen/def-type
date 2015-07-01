_ = require('lodash')

filter =
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

module.exports = filter