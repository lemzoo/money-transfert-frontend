'use strict'


angular.module('app.views.accueil', ['ngRoute'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/accueil',
        templateUrl: 'scripts/views/accueil/accueil.html'
        controller: 'AccueilController'

  .controller 'AccueilController', ($scope, $route, session, Backend, DelayedEvent, SETTINGS) ->
    $scope.user = {}
    $scope.PERMISSIONS = SETTINGS.PERMISSIONS
    $scope.ff_broker_rabbit = SETTINGS.FEATURE_FLIPPING.broker_rabbit

    session.getUserPromise().then (user) ->
      $scope.user = user.plain()
