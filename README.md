# def-type
![travis.ci](https://travis-ci.org/Zaggen/def-type.svg?branch=master "Build Status")

**This module is in active development, and still in beta, do not use in production.... yet**

## A Multiple composable inheritance module for js
def-type is an npm module that allows you to easily define Objects and classes that can inherit from a single parent
object by adding it to the prototype chain of the defined Object/Class (via the 'extends' directive) or from multiple 
objects or "classes" (via 'merges' directive), which also lets you to choose which attributes you merge(copy).
It also allows you to work with true shared privacy with almost the same syntax.
 
## Installation
`npm install def-type --save`

## Usage
```coffeescript
def = require('def-type')
```
**Class definition** (All attributes not defined in the constructor will live in the prototype obj)
```coffeescript
Character = def.Class
 constructor: ()->
  # some code
 setSkills: (newSkills = [])->
  # some code
  
Player = def.Class
  extends: Character # It will add the Character.prototype to the Player.prototype chain
  constructor: (@playerName)->
    Player._super.constructor.call(@) # Available when extending but not when merging.
  sayMsg: ->
    # some code
  kill: ->
    # some code

plyr1 = new Player('zaggen')
```
**Object definition** (Pretty much the same as defining an object literal)
```coffeescript
enemyBoss = def.Object
  extends: Character # It sets Character.prototype as the prototype of the enemyBoss obj
  killThemAll: ->
    # some code
  regenHpWhenAlmostDead: ->
    # some code

```
**Mixin definition** This is an alias of def.Object. It is recommended that you name your objects with 
the Traits suffix when they are supposed to be merged into other objects/classes, and when your Traits Object
needs to merge/mix in some functionality/properties from other objects/classes you use def.Mixin. This way
we get a performance boost when defining simple traits (What pretty much the rest of the js world calls a mixin),
and we only use this term to objects that are supposed to be merged/mixed in but they also merge/mix in other
objects/mixins/classes.

```coffeescript
# This is a traits Object
encryptingTraits =
  encrypt: ->
    # some code
  decrypt: ->
    # some code

# This is a Mixin Traits Object
accountTraits = def.Mixin
  merge: encryptingTraits
  logIn: (req, res)->
    # some code
  logOut: (req, res)->
    # some code

```
**Module definition** This is another alias for def.Object, it is recommended for npm style modules. So you can 
define functionality packed in a module(which is a regular object) that needs to expose a small public API.
```coffeescript
injector = def.Module ->
  @set = (fn)->
    # some code
  @get =  ->
    # some code
    
  # Private fns
  import = (path)->
   # some code
  importGlobal = (globalName)->
   #some code

```
Here is a working example using this option:
[commonjs-injector](https://github.com/Zaggen/commonjs-injector/blob/master/index.coffee)

#### Usage with multiple inheritance and defined constructor
You can inherit from multiple "Classes" or objects, or a mixture of both. 
```coffeescript
Admin = def.Class
  merges: [ accountTraits, ['logIn', 'logOut'],  User] # here User is a class
  constructor: (@name)->
    @privileges = 'all'
  deleteUser: ->
    # Some Code
  modifyUser: ->
    # Some Code

zaggen = new Admin('zaggen')
```
Please note that 'merges' copies the attributes or references to the defined item, so any change in the parents won't
be reflected in the defined item.

**Abstract definition** Sometimes you want to define an npm like module or a Class that is not supposed to be
used directly, but to be extended and it doesn't makes much sense as a Traits obj. You can define that kind of
object or class with def.Abstract. When you set a constructor it internally calls def.Class, and when you don't
it used def.Object, there is no special safety mechanism for preventing direct instantiation or usage, is up to
you as a programmer to follow this convention.
```coffeescript
FrontEndController = def.Abstract
  constructor: ->
    # some code
  _beforeFilter: ->
    # some code
  _afterFilter: ->
    # some code

# Here user controller is a FrontEndController and has accountTraits
UserController = def.Class
  extends: FrontEndController
  merges: [accountTraits]
  constructor: ->
    UserController._super.call(@)
```

#### Usage with real private methods and attrs(static/shared)
You can get true privacy when passing a lambda instead of an object, in this anonymous fn you will define your public
attrs as instance members of that fn, and your private attributes as local variables, the nice thing here is a that all
your public functions will have access to the private stuff (This is a closure that is executed internally) and you
can define your private variables at the bottom like in ruby, which is hard to do in cs because we only have fn 
expressions so we don't get hoisted fns... anyways, you can use private properties too (data) but this data will be 
shared across all instances of the class, so be aware of that, its usefull for objects, but not that much for classes.
You can use weakMaps to accomplish this but that is not something def-type will do for you, additionally bare in mind that
if you add public functions later, this fns can't access the previously defined private properties, because they will be
out of scope, so monkey patching is not possible, also you can't inherit private members. Is probably better to use
the underscore convention for private attrs in most cases, but sometimes you really want this behavior, so here it is.
```coffeescript
Admin = def.Class ->
  # private properties have to be defined at the top in cs
  instanceNumber = 0 # Static variable, will be shared accross all instances
  # Public
  @constructor = (@name)->
    instanceNumber++
    
  @getInstanceQ = -> return instanceNumber
  @deleteUser = (id)->
    dbQuery('delete', id)
  @modifyUser = (id, data)->
    dbQuery('modify', id, data)
    
  # Private Methods
  dbQuery = (action, id, data = {})->
    # Some Code
    
zaggen = new Admin('zaggen')
zaggen.deleteUser(5) # Works
zaggen.dbQuery('delete',5) # Won't work
```

#### Usage with real private methods and attrs(shared) and accessors
```coffeescript
user = def.Object ->
  name = 'John'
  lastName =  'Doe'
  @accessors = ['fullName'] # Add the names of the properties that you want to define as accessors
  @fullName =
    get: -> "#{name} #{lastName}"
    set: (fullName)->
      nameParts = fullName.split(' ')
      name = nameParts[0]
      lastName = nameParts[1]
    
console.log user.fullName # Logs 'John Doe'
user.fullName = 'Max Payne' # Sets the private name and lastName variables with the value provided
console.log user.fullName # Logs 'Max Payne'
```

## Features
* Set another object/Class as the prototype of the defined element (Using extends).
* Merge properties from other objects/classes into the defined element  (Using merges).
* You have composite options, meaning you can pick which attributes you merge and even set the context of methods to
 their original objects.
* A `_super` object is created when the defined type is being extended or merged, it will contain all of the inherited
(extended and merged) methods into it. This is useful when you want to override an inherited parent method but you still
want to have access to the original functionality. To avoid getting the wrong super, you must reference the defined
object or class instead of using `this`. Methods that makes changes to instance members should be called 
using `.call(this, arg1, arg2)` or `.apply(this,[args])`
* You can define 'classes' very easy, and extend them with out ,manually adding the parent class prototype to the 
currently defined class and setting back the original constructor, or adding methods to the prototype one by one.

## Merge options
When you pass an options array after the object to be merge, e.g:
```coffeescript
  merges: [ accountTraits, ['logIn', 'logOut'],  User]
```
You can specify which properties you merge into the defined obj/class, by combining the property names you want to
add or exclude from the mixin/class and/or a few optional flags (`!`, `*`,`~`).
* This are the options in details
  - `['attr1', 'attr2']` Will only include those selected attributes from the corresponding object
  - `['~publicMethod']`  ***This functionality will be deprecated in the next update*** Delegate; Will only include those selected method and it will bind its context to the original
   object/Class. 
  - `['!', 'privateAttr']` Will exclude the selected attr, and include the rest
  - `['!']` Will exclude all attributes. Only useful for debugging purposes
  - `['*']` Will include all attributes. By default if you don't provide a confArray there is no need to explicitly say
   to include all attributes, but if you like to be explicit here is the option.

## Examples
```coffeescript
def = require('def-type')

hardObjTraits =
  colliding: false
  isInCollision: ->
    # Detects if object is colliding with other hardObjs

movableTraits =
  x: 0
  y: 0
  move: (x, y, time)->
    # Moves from current x,y to the new pos in the given time
    
spriteTraits =
  setBitmap: (bitmap)->
    # Sets sprite to the specified bitmap
  update: ->
    # Updates sprite
    
# A Mixin is an object that mixes/merges in functionality from other objects and is supposed
# to be merged into another object or class and not to be used directly.
gameCharacterTraits = def.Mixin
  merges: [movableTraits, spriteTraits, hardObjTraits]
  _exp: 0
  lvlUp: (newExp)->
    @_increaseExp(newExp) # Private Method Call
    # Lvl up based on exp
    
  _increaseExp: (newExp)-> @_exp += newExp

# A defined Object is supposed to be used as it is, like a customized instance of Object.
hero = def.Object
  merges: [gameCharacterTraits]
  name: 'Zaggen'
  stats: 
    agi: 23
    def: 45
    str: 99
  
hero.move(100, 200, 100) # Moves the hero to position (100,200) in 100 milliseconds

killableTraits =
  _hp: 100
  kill: ()-> 
    #Set hp to 0, and show dead animation

Player = def.Class
  merges: [ gameCharacterTraits, ['~lvlUp'], killableTraits, ['kill'] ]
  constructor: (playerName)->
    @msg = "#{playerName} is ready to kill some goblins!"
  sayMsg: ->
    console.log @msg
  kill: ->
    Player._super.kill.call(@) # Unless kill is a pure fn with no side effects, it should be called using call or apply
    console.log 'Game Over'
  
zaggen = new Player('Zaggen')
zaggen.sayMsg() # Outputs "Zaggen is ready to kill some goblins!"
zaggen.lvlUp(100) #Increases exp, and if enough it'll lvl up the player
zaggen.move(15, 40, 10) # Moves the character to position (15,40) in 10 milliseconds
```

## Bugs, questions, ideas?
Hell, yeah, just open an issue and i'll try to answer ASAP. I'll appreciate any bug report with a proper way to
reproduce it.