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


angular.module('app.views.transfert', ['app.settings', 'ngRoute', 'ui.bootstrap',
                                         'xin.listResource', 'xin.solrFilters', 'xin.tools',
                                         'xin.session', 'xin.backend', 'angularMoment',
                                         'app.views.utilisateur.modal',
                                         'angular-bootstrap-select', 'xin.form'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/transfert-de-dossier',
        templateUrl: 'scripts/views/transfert/show_transfert.html'
        controller: 'TransfertController'
        breadcrumbs: 'Transfert'
        reloadOnSearch: false
        routeAccess: true,


  .controller 'TransfertController', ($scope, Backend, BackendWithoutInterceptor,
                                      $modal, SETTINGS, session,
                                      moment, DelayedEvent, $route) ->
    initWorkingScope($scope, $modal)
    session.getUserPromise().then (user) ->
      $scope.user = user
      $scope.prenoms = []
      $scope.api_url = SETTINGS.API_BASE_URL
      getUsagers = ->
        $scope.pf_usagers = []

        _retrieve_prefecture = (usager) ->
          Backend.one(usager.prefecture_rattachee._links.self).get().then(
            (site) ->
              usager.prefecture_rattachee_label = "#{site.libelle}"
          )

        if $scope.identifiant_agdref != ''
          Backend.one('/recherche_usagers_tiers?usagers=true&identifiant_agdref=' + $scope.identifiant_agdref).get().then(
            (items) ->
              if items['PLATEFORME']
                for usager in items['PLATEFORME']
                  if not usager.transferable
                    continue
                  _retrieve_prefecture(usager)
                  $scope.pf_usagers.push(usager)
          )

        nom = $scope.nom or ''
        prenoms = ''
        for prenom in $scope.prenoms or []
          prenoms += prenom + ' '
        date_naissance = $scope.date_naissance or ''
        sexe = $scope.sexe or ''

        # Check if nom is correctly formatted
        checkPatronymePattern = (str) ->
          low = "abcdefghijklmnopqrstuvwxyzáàâäåãæçéèêëíìîïñóòôöõøœšúùûüýÿž"
          up = low.toUpperCase()
          spe = " \-"

          final_regex = RegExp("^([" + up + "]|([" + up + "][" + up + low + spe + "]*[" + up + low + spe + "]))$")
          return final_regex.test(str)

        if !checkPatronymePattern(nom) or !checkPatronymePattern(prenoms) or nom == '' or prenoms == '' or sexe == ''
          return

        $scope.spinner = true
        r_nom = '&nom='+nom
        r_prenom = '&prenom='+prenoms
        r_date_naissance = '&date_naissance='+moment(date_naissance).format('YYYY-MM-DD')
        r_sexe = '&sexe='+sexe
        r_params = r_nom + r_prenom + r_sexe + r_date_naissance

        Backend.one('/recherche_usagers_tiers?usagers=true&' + r_params).get().then(
          (items) ->
            $scope.spinner = false
            if items['PLATEFORME']
              for usager in items['PLATEFORME']
                if not usager.transferable
                  continue
                _retrieve_prefecture(usager)
                $scope.pf_usagers.push(usager)

          (errors) ->
            $scope.spinner = false
        )

      delayedEvent = new DelayedEvent(1000)
      $scope.$watch 'nom', (value, old_value) ->
        delayedEvent.triggerEvent ->
          if value != old_value
            getUsagers()
      $scope.$watch 'prenoms', (value, old_value) ->
        if not angular.equals(value, old_value)
          getUsagers()
      , true
      $scope.$watch 'date_naissance', (value, old_value) ->
        delayedEvent.triggerEvent ->
          if value != old_value
            getUsagers()
      $scope.$watch 'sexe', (value, old_value) ->
        if value != old_value
          getUsagers()
      $scope.$watch 'identifiant_agdref', (value, old_value) ->
        if value != old_value
          getUsagers()

      $scope.transfert = (usager) ->
        modalInstance = $modal.open(
          controller: "ModalInstanceConfirmController"
          templateUrl: "scripts/xin/modal/modal.html"
          backdrop: false
          keyboard: false
          resolve:
            message: () ->
              return "La fiche de l'usager et la demande d'asile associée vont être transférées dans votre préfecture. Les données ne seront visibles que depuis cette préfecture."
            sub_message: -> return "Valider le tranfert?"
        )
        modalInstance.result.then (result) ->
          if not result
            $scope.saveDone.end?()
            return
          patch =
            prefecture_rattachee: $scope.user.site_rattache.id
          Backend.one('/usagers/' + usager.id + '/prefecture_rattachee').patch(patch).then(
            () ->
              modalInstance = $modal.open(
                controller: "ModalInstanceForceConfirmController"
                templateUrl: "scripts/xin/modal/modal.html"
                backdrop: false
                keyboard: false
                resolve:
                  message: () ->
                    return "L'usager a bien été transféré."
                  sub_message: -> return "Important : Dans le cas d'un usager demandeur (possédant un N° AGDREF), n'oubliez pas d'effectuer également le transfert du dossier dans AGDREF."
              )
              modalInstance.result.then (
                (result) ->
                  $route.reload()
              )
            (error) ->
              $scope.saveDone.end?()
          )
