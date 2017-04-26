"use strict"


angular.module('xin.plage_rdv', ['app.settings', 'ui.bootstrap', 'ui.calendar',
                                 'angularMoment', 'app.views.plage_rdv.modal',
                                 'xin.form'])

  .directive 'plageRdvPfDirective', () ->
    restrict: 'E'
    controller: 'plageRdvPfController'
    templateUrl: 'scripts/views/plage_rdv/directive/plage_rdv.html'
    scope:
      calendarCls: '='


  .controller 'plageRdvPfController', ($scope, $modal, $q, DelayedEvent, Backend,
                                       BackendWithoutInterceptor, uiCalendarConfig, guid) ->
    $scope.uiConfig = $scope.calendarCls.createUiConfig()
    $scope.type = $scope.calendarCls.calendar
