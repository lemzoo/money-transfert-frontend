'use strict'

class Storage
  constructor: (@storage) ->
  # Browser's storage api uses native code, must wrap the calls...
  getItem: (key) -> @storage.getItem(key)
  setItem: (key, value) =>
    @storage.setItem(key, value)
  removeItem: (key) =>
    @storage.removeItem(key)
  clear: -> @storage.clear()
  addEventListener: (handler) =>
    if window.addEventListener?
      #Normal browsers
      window.addEventListener "storage", handler, false
    else
      # for IE (why make your life more difficult)
      window.attachEvent "onstorage", handler

angular.module('xin.storage', [])
  .factory 'localStorage', -> new Storage(window.localStorage)
  .factory 'sessionStorage', -> new Storage(window.sessionStorage)
