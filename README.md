# Def-Inc
This is the same bakeIn module with modified syntax, to make it more explicit

**This module is in active development, and still in beta, do not use in production.... yet**

## A Multiple composable inheritance module for js
def-inc is a module that allows you to easily define Objects or classes that can inherit from multiple objects or "classes",
and lets you to choose which attributes you inherit (Pick/omit/delegate). It also allows you to work with true privacy
with almost the same syntax.
 

## Installation
`npm install def-inc --save`

## Usage
```coffeescript
def = require('def-inc')
```
**Class definition** (All attributes not defined in the constructor will live in the prototype obj)
```coffeescript
Player = def.Class({
  constructor: (@playerName)->
    # some code
  sayMsg: ->
    # some code
  kill: ->
    # some code
})
plyr1 = new Player('zaggen')
```
**Object definition** (Pretty much the same as defining an object literal)
```coffeescript
accountTraits = def.Object({
  logIn: (req, res)->
    # some code
  logOut: ((req, res)->
    # some code
})
```
#### Usage with multiple inheritance and defined constructor
You can inherit from multiple "Clases" or objects, or a mixture of both. 
```coffeescript
Admin = def.Class(
  include_: [ accountTraits, ['logIn', 'logOut'],  User, ['*'] ]
  constructor: (@name)->
    @privileges = 'all'
  deleteUser: ->
    # Some Code
  modifyUser: ->
    # Some Code
)
zaggen = new Admin('zaggen')
```
#### Usage with real private methods and attrs(shared)
You can use true privacy. Only for methods, you can define private attributes, but they will be shared attr(js fault),
so its only usefull for objects or when you want that attribute shared, you can use weakMaps to overcome this, but
the point here is to be able to define private methods. You can't inherit these attributes.
```coffeescript
Admin = def.Class ->
  # private properties have to be defined at the top in cs
  instanceNumber = 0
  # Public
  @constructor = (@name)->
    @privileges = 'all'
  @deleteUser = (id)->
    dbQuery('delete', id)
  @modifyUser = (id, data)->
    dbQuery('modify', id, data)
    
  # Private Methods
  dbQuery = (action, id, data = {})->
    # Some Code
    
  this

zaggen = new Admin('zaggen')
zaggen.deleteUser(5) # Works
zaggen.dbQuery('delete',5) # Won't work
```

## Inheriting
* `baseObjectN` **Object** (Optional) Objects to extend the receivingObj, they will take precedence from last to first.
* `configN` **Array** (Optional) with flags(`!`, `*`,`~`) and/or attribute names, e.g:
  - `['attr1', 'attr2']` Will only include those selected attributes from the corresponding object
  - `['~publicMethod']` Delegate; Will only include those selected method and it will bind its context to the original baseObject. This is useful, when you have an object with "public" methods that make use of internal "private" methods, and you don't want to inherit those, this way this inherited method will be able to call all the needed attributes and methods from its original obj. Use this sparingly since it will bite you if you try to use it incorrectly. Just remember that the inherit method will not have access to any of your attributes/methods defined/inherited in the receivingObj. Also, this flag is ignored for non function attributes, and when the exclude flag is set, since we can't bind an excluded method...
  - `['!', 'privateAttr']` Will exclude the selected attr, and include the rest
  - `['!']` Will exclude all attributes. Only useful for debugging purposes
  - `['*']` Will include all attributes. By default if you don't provide a confArray there is no need to explicitly say to include all attributes, but if you use at least one confArray for any of your objects, you must use them for the rest, this is to avoid ambiguity, so use the `*` in those cases.
* `receivingObj` **Object** The object to extend.

## Examples
```coffeescript
def = require('def-inc')

hardObj = 
  colliding: false
  isInCollision: ->
    # Detects if object is colliding with other hardObjs

movable = 
  x: 0
  y: 0
  move: (x, y, time)->
    # Moves from current x,y to the new pos in the given time
    
sprite = 
  setBitmap: (bitmap)->
    # Sets sprite to the specified bitmap
  update: ->
    # Updates sprite
    
gameCharacter = def.Object(
  include_: [movable, sprite, hardObj]
  _exp: 0
  lvlUp: (newExp)->
    @_increaseExp(newExp) # Private Method Call
    # Lvl up based on exp
    
  _increaseExp: (newExp)-> @_exp += newExp
)
    
gameCharacter.move(100, 200, 100) # Moves the character to position (100,200) in 100 milliseconds

killable = 
  kill: ()-> 
    #Set hp to 0, and show dead animation

Player = def.Class(
  include_: [ gameCharacter, ['~lvlUp'], killable, ['kill'] ]
  constructor: (playerName)->
    @msg = "#{playerName} is ready to kill some goblins!"
  sayMsg: ->
    console.log @msg
  kill: ->
    @_super.kill()
    console.log 'Game Over'
  
zaggen = new Player('Zaggen')
zaggen.sayMsg() # Outputs "Zaggen is ready to kill some goblins!"
zaggen.lvlUp(100) #Increases exp, and if enough it'll lvl up the player
zaggen.move(15, 40, 10) # Moves the character to position (15,40) in 10 milliseconds
```

## Features
* Extend any object with one or many other objects/mixins
* You have composite options, meaning you can pick which attributes you inherit and even set the context of methods to their original objects.
* A `_super` object is created when extending the receivingObj, it will contain all of the inherited methods into it. This is useful when you want to override an inherited parent method but you still want to use the original functionality.
* If you provide a constructor in the receivingObj, you will get a constructor function.


## Bugs, questions, ideas?
Hell, yeah, just open an issue and i'll try to answer ASAP. I'll appreciate any bug report with a propper way to reproduce it.