mocks =
  mixin1:
    sum: (numbers...)->
      r = 0
      r += n for n in numbers
      return r

    multiply: (numbers...)->
      r = 1
      r *= n for n in numbers
      return r

  mixin2:
    pow: (base, num)->
      nums = []
      for i in [1...num]
        nums.push(num)
      return @multiply.apply(this, nums)

  mixin3:
    increaseByOne: (n)->
      @sum(n, 1)

  mixin4:
    _privateAttr: 5
    publicMethod: (x)->  @_privateMethod(x)
    _privateMethod: (x)-> x * @_privateAttr
    _privateMethod4: (x)-> x / @_privateAttr
    _privateMethod2: (x)-> x + @_privateAttr
    _privateMethod3: (x)-> x - @_privateAttr

  mixin5:
    enable: true
    preferences:
      fullScreen: true
      muted: false
    favoriteChannels: [12,51]

  mixin6:
    increaseByOne: (n)->  @sum(n, 1)
    enable: false
    itemList: ['item5']

module.exports = mocks