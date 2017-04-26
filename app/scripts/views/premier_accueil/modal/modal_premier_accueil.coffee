'use strict'


angular.module('app.views.premier_accueil.modal', [])
  .controller 'ModalInstanceConfirmSaveController', ($scope, $modalInstance, recueil_da, action) ->
    $scope.recueil_da = recueil_da
    $scope.action = action
    $scope.ok = ->
      $modalInstance.close(true)
    $scope.cancel = ->
      $modalInstance.close(false)


  .controller 'ModalInstanceRecueilSavedController', ($scope, $modalInstance, recueil_da) ->
    $scope.recueil_da = recueil_da
    $scope.listRecueils = ->
      $modalInstance.close('list')
    $scope.showRecueil = ->
      $modalInstance.close('show')


  .controller 'ModalInstanceRecueilValidatedController', ($scope, $modalInstance, recueil_da) ->
    $scope.recueil_da = recueil_da
    $scope.listRecueils = ->
      $modalInstance.close('list')
    $scope.showRecueil = ->
      $modalInstance.close('show')
    $scope.showRdv = ->
      $modalInstance.close('rdv')


  .controller 'ModalLanguagesController', ($scope, $modalInstance, languages) ->
    $scope.language = ""
    $scope.languages = languages
    $scope.label = "Langue de traduction"
    $scope.valid = ->
      $modalInstance.close($scope.language)
    $scope.cancel = ->
      $modalInstance.close(false)
