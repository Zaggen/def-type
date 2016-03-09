# Allows rebinding
# http://www.angrycoding.com/2011/09/to-bind-or-not-to-bind-that-is-in.html
bind = (functionObject)->
  # do regular bind
  result = functionObject.bind.apply(
    functionObject,
    Array.prototype.slice.call(arguments, 1)
  )
  # overwrite bind by the one that will use
  # original function instead of it's binded version
  result.bind = (args...)->
    Function.prototype.bind.apply(functionObject, args)

  # return binded function
  return result

module.exports = bind
