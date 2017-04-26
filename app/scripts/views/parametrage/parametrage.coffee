'use strict'

initWorkingScope = (scope, $modal) ->
  scope.working = false
  scope.saveDone = {}
  scope.workingModal = ->
    modalInstance = $modal.open(
      templateUrl: 'scripts/xin/modal/modal.html'
      controller: 'ModalInstanceAlertController'
      resolve:
        message: -> return "Un traitement est en cours."
    )


angular.module('app.views.parametrage', ['app.settings', 'ngRoute', 'ui.bootstrap',
                                         'xin.listResource', 'xin.tools',
                                         'xin.session', 'xin.backend', 'angularMoment',
                                         'angular-bootstrap-select', 'xin.form'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/parametrage',
        templateUrl: 'scripts/views/parametrage/show_parametrage.html'
        controller: 'ShowParametrageController'
        breadcrumbs: 'Paramétrage'
        routeAccess: true


  .controller 'ShowParametrageController', ($scope, $route, $routeParams, moment,
                                            $modal, Backend, session, SETTINGS, DelayedEvent) ->
    initWorkingScope($scope, $modal)
    Backend.one('parametrage').get().then(
      (parametrage) ->
        $scope.parametrage = parametrage
      (error) -> window.location = '#/404'
    )

    $scope.saveParametrage = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return "Vous allez enregistrer ce nouveau paramétrage"
          sub_message: ->
            return ''
      )
      modalInstance.result.then (answer) ->
        if answer
          payload =
            duree_attestation: $scope.parametrage.duree_attestation

          Backend.one('parametrage').patch(payload, null, {'if-match' : $scope.parametrage._version}).then(
            (parametrage) ->
              modalInstance = $modal.open(
                templateUrl: 'scripts/xin/modal/modal.html'
                controller: 'ModalInstanceForceConfirmController'
                backdrop: false
                keyboard: false
                resolve:
                  message: ->
                    return "Le nouveau paramétrage a bien été sauvegardé."
                  sub_message: ->
                    return ""
              )
              modalInstance.result.then () ->
                $route.reload()
            (error) ->
              $scope.saveDone.end?()
              throw error
          )
        else
          $scope.saveDone.end?()
