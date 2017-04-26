'use strict'


angular.module('xin.recueil_da.modal', [])

  .controller 'ModalInstanceConfirmCancelController', ($scope, $modalInstance) ->
    $scope.motif = ""

    $scope.ok = ->
      if ($scope.motif == "" or $scope.motif == undefined)
        $scope.motif_error = "Champs obligatoire"
      else
        $modalInstance.close($scope.motif)

    $scope.cancel = ->
      $modalInstance.close(false)
