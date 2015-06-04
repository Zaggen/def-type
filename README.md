# Def-Inc
This is the same bakeIn module with modified syntax, to make it more explicit

```coffeescript
killable = define.Object(
  kill: ->
    # some code
)

Player = define.Class(
  prototype_: GameObj
  include_: [ gameCharacter, ['~lvlUp'], killable, ['kill'] ]
  constructor: (playerName)->
    # some code
  sayMsg: ->
    # some code
  kill: ->
    # some code
)
```