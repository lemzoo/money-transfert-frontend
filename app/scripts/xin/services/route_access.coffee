'use strict'


angular
  .module('xin.routeAccess', [
    'ngRoute',
    'xin.session',
  ])

  .run ($rootScope, $location, $route, session) ->
    checkRouteAccess = (currentRoute) ->
      if currentRoute.routeAccess?
        if typeof(currentRoute.routeAccess) != 'boolean'
          route = currentRoute.routeAccess
        else
          route = $route.current.$$route.originalPath
        session.can(route).then(
          ->
          -> _.defer -> $location.path('/403')
        )
    $rootScope.$on '$routeChangeSuccess', (currentRoute, previousRoute) ->
      checkRouteAccess($route.current.$$route)
      return
