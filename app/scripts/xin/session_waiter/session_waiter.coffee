'use strict'


angular.module('xin.sessionWaiter', [])

  .directive 'xinSessionWaiter', (session, Backend) ->
    transclude: true
    templateUrl: 'scripts/xin/session_waiter/session_waiter.html'
    link: (scope, elem, attrs, ctrl, transclude) ->
      scope.sessionWaiterWaiting = true
      session.getUserPromise().then(
        (user) -> scope.sessionWaiterWaiting = false
        (error) -> scope.sessionWaiterWaiting = false
      )
