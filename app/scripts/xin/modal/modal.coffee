'use strict'


angular.module('xin.modal', [])
  .controller 'ModalInstanceConfirmController', ($scope, $modalInstance, message, sub_message) ->
    $scope.message = message
    $scope.sub_message = sub_message
    $scope.ok_text = "Confirmer"
    $scope.cancel_text = "Annuler"
    $scope.confirm = true
    $scope.ok = ->
      $modalInstance.close(true)
    $scope.cancel = ->
      $modalInstance.close(false)

  .controller 'ModalInstanceForceConfirmController', ($scope, $modalInstance, message, sub_message) ->
    $scope.message = message
    $scope.sub_message = sub_message
    $scope.ok_text = "Confirmer"
    $scope.ok = ->
      $modalInstance.close(true)

  .controller 'ModalInstanceAlertController', ($scope, $modalInstance, message) ->
    $scope.message = message
    $scope.confirm = false
    $scope.ok_text = "Fermer"
    $scope.ok = ->
      $modalInstance.close()
