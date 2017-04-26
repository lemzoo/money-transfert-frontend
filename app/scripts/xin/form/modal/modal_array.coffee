'use strict'


angular.module('xin.form.array.modal', [])
  .controller 'ModalArrayController', ($scope, $modalInstance, row, origin_row) ->
    $scope.row = {}
    $scope.libelles = null
    if row?
      angular.copy(row, $scope.row)
    if origin_row
      angular.copy(origin_row, $scope.origin_row)

    $scope.valid = ->
      if $scope.row.pays?
        if typeof($scope.row.pays) == 'string'
          if $scope.row.pays == ""
            delete $scope.row.pays
          else
            $scope.row.pays =
              code: $scope.row.pays
              libelle: $scope.libelles[0]
      if not $scope.row.date_entree
        delete $scope.row.date_entree
      if not $scope.row.date_sortie
        delete $scope.row.date_sortie
      $modalInstance.close($scope.row)

    $scope.cancel = ->
      $modalInstance.dismiss('cancel')
