"use strict"


angular.module('app.views.remise_titres.modal', [])

  .controller 'ModalRechercheIDController', ($scope, $modalInstance, $q,
                                             BackendWithoutInterceptor, numero_etranger,
                                             retrieveFneUsager, search_on_open) ->

    $scope.numero_etranger = numero_etranger
    $scope.portail_usager = null
    $scope.fne_usager = null
    $scope.searchDone = {}
    $scope.can_finish = false
    $scope.error = null
    $scope.no_fne = false
    $scope.no_result = false

    $scope.search = ->
      $scope.error = null
      $scope.no_fne = false
      $scope.no_result = false

      if not $scope.numero_etranger? or not $scope.numero_etranger.match(/^[0-9]{10}$/)
        $scope.error = "Le numéro étranger doit être composé de 10 chiffres"
        stop_search()
        return

      $scope.portail_usager = null
      $scope.fne_usager = null

      retrieve_pf_usager().then () ->
        retrieveFneUsager($scope.numero_etranger).then(
          (usager) ->
            if Object.keys(usager.plain()).length
              $scope.fne_usager = usager.plain()
            if not $scope.portail_usager and not $scope.fne_usager
              $scope.no_result = true
            stop_search()
          () ->
            $scope.no_fne = true
            if not $scope.portail_usager
              $scope.no_result = true
            stop_search()
        )

    stop_search = () ->
      $scope.searchDone.end?()

    retrieve_pf_usager = () ->
      defer = $q.defer()
      url = "/recherche_usagers_tiers?usagers=true&identifiant_agdref=#{$scope.numero_etranger}"
      BackendWithoutInterceptor.one(url).get().then(
        (usagers) ->
          if usagers.PLATEFORME?.length
            $scope.portail_usager = usagers.PLATEFORME[0]
          defer.resolve()
        (error) ->
          defer.resolve()
      )
      return defer.promise

    $scope.finish = (usager, source) ->
      if usager? then $modalInstance.close({usager: usager, source: source})

    $scope.cancel = ->
      $modalInstance.dismiss()

    if search_on_open then $scope.search()
