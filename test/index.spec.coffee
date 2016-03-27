global.expect = require('chai').expect
global.def = require('../index')
global.mocks = require('./mocks')
global.log = console.log
require('colors')

global.mixin1 = mocks.mixin1
global.mixin2 = mocks.mixin2
global.mixin3 = mocks.mixin3
global.mixin4 = mocks.mixin4
global.mixin5 = mocks.mixin5
global.mixin6 = mocks.mixin6

require('./methods-basics.spec.coffee')
require('./object-definition.spec.coffee')
require('./class-definition.spec.coffee')
