'use strict'


angular.module('xin.testBackendConnexion', [])
  .factory 'backendConnexion', ->
    isDown = false

    setStatus: (status) ->
      if status == 0
        isDown = true
      else
        isDown = false

    getStatus: ->
      return isDown

  .controller 'testBackendConnexionController', ($scope, backendConnexion) ->
    $scope.$watch backendConnexion.getStatus, (new_value, old_value) ->
      $scope.backendIsDown = new_value

  .directive 'testBackendConnexionDirective', (backendConnexion)->
    transclude: true
    templateUrl: 'scripts/xin/test_backend_connexion/test_backend_connexion.html'
    controller: 'testBackendConnexionController'
    scope:
      backendIsDown: '=?'
    link: (scope, elem, attrs, ctrl, transclude) ->
      scope.backendIsDown = false
