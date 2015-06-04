# Def - Inc
**This module is in active development, and still in beta, do not use in production.... yet**
## A Multiple composable inheritance module for js
BakeIn is a helper function to use object composition, so it allows an object to be extended/inherit from other objects properties (own properties), pretty much like  lodash `extend`.With a couple of differences, that makes a huge impact in power, flexibility and clarity. First the order of arguments is reversed, this allows a CoffeeScript *Class-like* workflow when working with objects, so the last argument will be our targetObj where we define our new properties and methods. Second we can choose which attributes we inherit from all of the baseObjects/mixins, and lastly the `bakeIn` fn can return a constructor function when we specify a constructor in any of the objects passed to the function, though ideally this constructor should be defined in the receiving obj.

## Installation
`npm install bake-in --save`

## Usage
Returns the receivingObj/TargetObj
```coffeescript
bakeIn([baseObjectN], [configN], receivingObj)
```
#### Usage with multiple inheritance and defined constructor
You can inherit from multiple "Clases" or objects, or a mixture of both. 
```coffeescript
Admin = bakeIn(
  Account, ['logIn', 'logOut'],
  User, ['*'], 
  constructor: (@name)->
    @privileges = 'all'
  deleteUsers: ->
    # Some Code
  modifyUsers: ->
    # Some Code
)
zaggen = new Admin('zaggen')
```
## Arguments
* `baseObjectN` **Object** (Optional) Objects to extend the receivingObj, they will take precedence in reverse order, being the last  one before the receivingObj the one that will take more precedence.
* `configN` **Array** (Optional) with flags(`!`, `*`,`~`) and/or attribute names, e.g:
  - `['attr1', 'attr2']` Will only include those selected attributes from the corresponding object
  - `['~publicMethod']` Will only include those selected method and it will bind its context to the original baseObject. This is useful, when you have an object with "public" methods that make use of internal "private" methods, and you don't want to inherit those, this way this inherited method will be able to call all the needed attributes and methods from its original obj. Use this sparingly since it will bite you if you try to use it incorrectly. Just remember that the inherit method will not have access to any of your attributes/methods defined/inherited in the receivingObj. Also, this flag is ignored for non function attributes, and when the exclude flag is set, since we can't bind an excluded method...
  - `['!', 'privateAttr']` Will exclude the selected attr, and include the rest
  - `['!']` Will exclude all attributes. Only useful for debugging purposes
  - `['*']` Will include all attributes. By default if you don't provide a confArray there is no need to explicitly say to include all attributes, but if you use at least one confArray for any of your objects, you must use them for the rest, this is to avoid ambiguity, so use the `*` in those cases.
* `receivingObj` **Object** The object to extend.

## Examples
```coffeescript
bakeIn = require('bakeIn') # You can call it extend/compose/mixIn what ever suits you

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
    
gameCharacter = bakeIn movable, sprite, hardObj,
  _exp: 0
  lvlUp: (newExp)->
    @_increaseExp(newExp) # Private Method Call
    # Lvl up based on exp
    
  _increaseExp: (newExp)-> @_exp += newExp
    
gameCharacter.move(100, 200, 100) # Moves the character to position (100,200) in 100 milliseconds

killable = 
  kill: ()-> 
    #Set hp to 0, and show dead animation

Player = bakeIn gameCharacter, killable
  ['~lvlUp'],
  ['kill'],
  # If you add a constructor method here, bakeIn will return constructor function.
  # If any other object has a constructor, it'll be saved in the @_super obj (only the last one is saved) and you
  # can called just like any other super method, but you must provide the context as its first argument.
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
### Optional syntax usage for the last example
This order allows to to be more explicit about what are you inheriting and from which obj, but you have to use `()` in CF, you would have to use them in js though, so is up to you. It only matters that you provide an equal number of objects and optionsArrays (Or none) and each one corresponds to the other.
```coffeescript
Player = bakeIn(
  gameCharacter, ['~lvlUp']
  killable, ['kill'],
  constructor: (playerName)->
    # some code
  sayMsg: ->
    # some code
  kill: ->
    # some code
)
```
## Features
* Extend any object with one or many other objects/mixins
* You have composite options, meaning you can pick which attributes you inherit and even set the context of methods to their original objects.
* A `_super` object is created when extending the receivingObj, it will contain all of the inherited methods into it. This is useful when you want to override an inherited parent method but you still want to use the original functionality.
* If you provide a constructor in the receivingObj, you will get a constructor function.

## Why bother?
 > "Favor 'object composition' over 'class inheritance'."
 -GoF
 
Traditional object composition is done by creating instances of the classes that have the functionality we want in a particular class/obj, but i think we can get the benefits from object composition in a different way in js (A much better way) with multiple inheritance, something that i call *Multiple composable inheritance*.
Lets face it, Inheritance is weird and verbose in javascript(es5) when using constructors, not really in coffeescript, and i must say i love the CoffeeScript class syntax, but sometimes single inheritance just doesn't make sense when you want to inherit multiple functionality from different objects that may not have a direct relationship, so if you actually do that you might end up with a lot of redundancy classes and a weird inheritance chain, but hey we can do that via mixins by calling something like `_.extend` after (at the bottom) the constructor/class definition, but to me is better to have the objects from which we inherit at top but using regular extend fns we can't, not at least until es7 decorators maybe?. 
Now this module is really flexible, because you can choose/compose the attributes/traits that you want to inherit, this is just not possible with the native behavior of both js or cs, or even _.extend or many of the tools to extend an object out there.

### Caveat
We can only call via _super the constructor defined last on any obj/class before the receiving obj. At least for now.

**Note:** Even though the module is called `bakeIn`, name it whatever you like, `compose`, `extend`, `mixIn`, etc.

## Examples Using sails.js controllers
```coffeescript

# BaseController.coffee
BaseController =
  index: (req, res)->
    res.json("action": "index")
  
  show: (req, res)->
    res.json("action": "show")
    
  fu: (req, res)->
    res.json("action": "fu")
```
 
```coffeescript  
# SecondController.coffee  
SecondController =
  filter: (req, res)->
      res.json("action": "filter")
```

```coffeescript
# ProductController.coffee 
compose = require('bake-in')
ProductController =  compose BaseController, SecondController
  ['index', 'show'],
  ['*'],
  
  index: (req, res)->
    console.log 'Overriding super'
    @_super.index(req, res)
  
  bar: (req, res)->
    res.json("action": "bar")
```

```coffeescript
# FooController.coffee 
extend = require('bake-in') # I'm naming the bakeIn Module as extend, just to show you a more familiar syntax if you like

# BakesIn/MixesIn all attributes from BaseController into the FooController
FooController =  extend BaseController
  bar: (req, res)->
    res.json("action": "bar")
```
## ChangeLog
* 5/24/2015 - Now you can inherit from "classes" (constructor functions, cs/es6 classes, or bakeIn Clasess)
* 5/23/2015 - Changed the behavior when a constructor is provided. Now instead of getting an object with a factory
 method (called new), we are returning a constructor, i think this is a more standard way to instantiate objects,
 and it performs way better.

## Bugs, questions, ideas?
Hell, yeah, just open an issue and i'll try to answer ASAP. I'll appreciate any bug report with a propper way to reproduce it.
