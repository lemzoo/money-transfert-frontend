'use strict'


angular.module('app.views.attestation.modal', [])

  .controller 'ModalInstanceConfirmAttestationController', ($scope, $modalInstance, Backend, procedure, date_decision_sur_attestation) ->
    $scope.date_debut_validite = moment(date_decision_sur_attestation)
    $scope.sous_type = ''

    $scope.procedure = ''
    if procedure == 'NORMALE'
      $scope.procedure = 'normale'
    if procedure == 'ACCELEREE'
      $scope.procedure = 'acceleree'
    if procedure == 'DUBLIN'
      $scope.procedure = 'dublin'

    Backend.one('parametrage').get().then(
      (parametrage) ->
        $scope.parametrage = parametrage
        $scope.duree_attestation = (($scope.parametrage.duree_attestation or {}).premiere_delivrance or {})
        $scope.duree_procedure = ($scope.duree_attestation[$scope.procedure] or {'an' : 0, 'mois' : 0, 'jour' : 0})
        $scope.an = ($scope.duree_procedure.an or 0)
        $scope.mois = ($scope.duree_procedure.mois or 0)
        $scope.jour = ($scope.duree_procedure.jour or 0)

        $scope.$watch 'date_debut_validite', (value) ->
          $scope.date_fin_validite = moment(value).utc()
          if $scope.date_fin_validite.date() == 1
            $scope.date_fin_validite.add($scope.mois, 'month')
            $scope.date_fin_validite.add($scope.jour, 'day')
          else
            $scope.date_fin_validite.add($scope.jour, 'day')
            $scope.date_fin_validite.add($scope.mois, 'month')
          $scope.date_fin_validite.add($scope.an, 'year')

      (error) -> window.location = '#/404'
    )


    $scope.ok = ->
      result =
        'date_debut_validite' : $scope.date_debut_validite
        'date_fin_validite' : $scope.date_fin_validite
        'date_decision_sur_attestation' : date_decision_sur_attestation
      $modalInstance.close(result)
    $scope.cancel = ->
      $modalInstance.close(false)
