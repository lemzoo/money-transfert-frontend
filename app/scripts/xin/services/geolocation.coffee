'use strict'


angular.module('xin.geolocation', [])
  .factory 'geolocation', ->
    if navigator.geolocation
      navigator.geolocation
      # TODO stub/throw errors if navigator is not available
