'use strict'


angular.module('xin.location', ['xin.tools', 'xin.referential'])
  .directive 'inputLocationDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/location/location.html'
    controller: 'InputLocationController'
    scope:
      location: '=?'
      canEdit: '=?'
      canUnknown: '=?'
      uDisabled: '=?'
    link: (scope, elem, attrs) ->
      if !scope.canUnknown?
        scope.canUnknown = true

      if !scope.location?
        scope.location =
          adresse_inconnue: false

      if !scope.location.adresse_inconnue?
        scope.location.adresse_inconnue = false

      scope.$watch 'location', (value) ->
        if value?
          scope.inputLocation = value.label
          if !scope.location.adresse_inconnue?
            scope.location.adresse_inconnue = false

      scope.$watch 'canEdit', (value) ->
        if value?
          scope.canEdit = value.label



  .controller 'InputLocationController', ($scope, $http, DelayedEvent, SETTINGS) ->
    locations = []
    $scope.searchLocations = []
    $scope.searchVilles = []

    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    $scope.$watch 'inputLocation', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue && filterValue != ''
          config =
            params: { q: filterValue, 'type': 'housenumber'}
          $http.get(SETTINGS.ETALAB_DOMAIN, config)
            .success( (data, status, headers, config) ->
              $scope.searchLocations = data.features
              $scope.error_etalab = ''
            )
            .error( (data, status, headers, config) ->
              $scope.error_etalab = 'Il est impossible de joindre le service ETALAB actuellement'
            )
        else
          $scope.searchLocations = []

    # Clean location fields when we click on the "adresse_inconnue" button
    $scope.$watch 'location.adresse_inconnue', (new_value, old_value) ->
      if !$scope.location?
        $scope.location =
          adresse_inconnue: new_value
      else
        if $scope.location.adresse_inconnue == true
          $scope.location =
            adresse_inconnue: new_value
        else
          $scope.location.adresse_inconnue = new_value

    # Delete country when the referential is canceled.
    $scope.$watch 'location.pays.code', (new_value, old_value) ->
      if new_value == '' or new_value == null or new_value == undefined
        delete($scope.location.pays)

    villeListenerStop = ->
    villeListenerStart = ->
      villeListenerStop = $scope.$watch 'ville_searcher', (newValue, oldValue) ->
        delayedFilter.triggerEvent ->
          if newValue? and newValue != '' and newValue != oldValue
            $scope.tmpSearchVilles = []
            $scope.searchVilles = []

            config =
              params: { q: newValue, 'type': 'city'}
            $http.get(SETTINGS.ETALAB_DOMAIN, config)
              .success( (data, status, headers, config) ->
                for feature in data.features
                  $scope.tmpSearchVilles.push(feature)
                $scope.error_etalab = ''
                config =
                  params: { q: newValue, 'type': 'town'}
                $http.get(SETTINGS.ETALAB_DOMAIN, config)
                  .success( (data, status, headers, config) ->
                    for feature in data.features
                      $scope.tmpSearchVilles.push(feature)
                    config =
                      params: { q: newValue, 'type': 'village'}
                    $http.get(SETTINGS.ETALAB_DOMAIN, config)
                      .success( (data, status, headers, config) ->
                        $scope.error_etalab = ''
                        for feature in data.features
                          $scope.tmpSearchVilles.push(feature)
                        config =
                          params: { q: newValue, 'type': 'municipality'}
                        $http.get(SETTINGS.ETALAB_DOMAIN, config)
                          .success( (data, status, headers, config) ->
                            for feature in data.features
                              $scope.tmpSearchVilles.push(feature)
                            $scope.error_etalab = ''
                            $scope.searchVilles = $scope.tmpSearchVilles
                          )
                          .error( (data, status, headers, config) ->
                            $scope.error_etalab = 'Il est impossible de joindre le service ETALAB actuellement'
                          )
                      )
                      .error( (data, status, header, config) ->
                        $scope.error_etalab = 'Il est impossible de joindre le service ETALAB actuellement'
                      )
                  )
                  .error( (data, status, header, config) ->
                    $scope.error_etalab = 'Il est impossible de joindre le service ETALAB actuellement'
                  )
              )
              .error( (data, status, headers, config) ->
                $scope.error_etalab = 'Il est impossible de joindre le service ETALAB actuellement'
              )
          else
            $scope.searchVilles = []
      , true

    $scope.startVille = ->
      villeListenerStart()

    $scope.clickVille = (location) ->
      villeListenerStop()
      if !location.properties.citycode
        $scope.error_ville = 'La ville choisie ne contient pas de code Insee'
      else
        $scope.error_ville = ''
        $scope.ville_searcher = ''
        $scope.location.ville = location.properties.city
        $scope.location.code_insee = location.properties.citycode
        $scope.location.code_postal = location.properties.postcode
        $scope.searchVilles = []
        villeListenerStart()

    $scope.cleanVille = ->
      $scope.location.ville = ''
      $scope.location.code_insee = ''
      $scope.location.code_postal = ''

    $scope.clickLocation = (location) ->
      villeListenerStop()
      $scope.location =
        chez: ''
        complement: ''
        numero_voie: location.properties.housenumber
        voie: location.properties.name
        ville: location.properties.city
        code_insee: location.properties.citycode
        code_postal: location.properties.postcode
        pays:
          code: SETTINGS.DEFAULT_COUNTRY
        longlat: location.geometry.coordinates
        adresse_inconnue: false
        identifiant_ban: location.properties.id
      villeListenerStart()

      if $scope.location.voie.indexOf($scope.location.numero_voie + ' ') == 0 || $scope.location.voie.indexOf($scope.location.numero_voie + ',') == 0
        $scope.location.voie = $scope.location.voie.substr($scope.location.numero_voie.length + 1)
