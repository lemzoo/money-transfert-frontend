'use strict'


angular.module('app.views.site.modal', ['ui.bootstrap.datetimepicker'])
  .controller 'ModalInstanceSiteCreatedController', ($scope, $modalInstance, site) ->
    $scope.site = site
    $scope.listSites = ->
      $modalInstance.close('list')
    $scope.showSite = ->
      $modalInstance.close('show')


  .controller 'ModalInstanceConfirmNewSiteController', ($scope, $modalInstance, site) ->
    $scope.site = site
    $scope.ok = ->
      $modalInstance.close(true)
    $scope.cancel = ->
      $modalInstance.close(false)


  .controller 'ModalInstanceCloseSiteController', ($scope, $modalInstance, site) ->
    $scope.site = site
    $scope.site.date_fermeture = new Date()

    $scope.open = ($event) ->
      $event.preventDefault()
      $event.stopPropagation()
      $scope.opened = true

    $scope.ok = ->
      $modalInstance.close($scope.site.date_fermeture)
    $scope.cancel = ->
      $modalInstance.close(false)
