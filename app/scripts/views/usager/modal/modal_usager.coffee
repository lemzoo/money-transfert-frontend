'use strict'


angular.module('app.views.usager.modal', [])
  .controller 'ModalRelocateUsagerController', ($scope, $modalInstance, Backend, usager) ->
    $scope.sites_url = "sites?fq=type:Prefecture"
    $scope.prefecture_rattachee =
      id: ""
    $scope.site = null
    $scope.etat = "form"

    $scope.$watch 'prefecture_rattachee', (value) ->
      if value? and value.id != ""
        Backend.one("sites/#{value.id}").get().then (site) ->
          $scope.site = site.plain()
      else
        $scope.site = null
    , true

    $scope.ok = ->
      $scope.etat = "confirm"

    $scope.confirm = ->
      if $scope._errors?
        delete $scope._errors.prefecture_rattachee
        delete $scope._errors.usager
      patch =
        prefecture_rattachee: $scope.prefecture_rattachee.id
      Backend.one("/usagers/#{usager.id}").customOperation("patch", "prefecture_rattachee", null, {"if-match": usager._version}, patch).then(
        () ->
          $scope.etat = "success"
        (error) ->
          if error.data._errors[0].usager == "Usager non transférable"
            $scope._errors =
              usager: error.data._errors[0].usager
          else
            $scope._errors =
              prefecture_rattachee: "La préfecture est obligatoire."
          $scope.etat = "form"
      )

    $scope.success = ->
      $modalInstance.close(true)

    $scope.cancel = ->
      $modalInstance.close(false)



  .controller 'ModalChangeAddressController', ($scope, $modalInstance, Backend, usager) ->
    $scope.localisation = usager.localisation
    $scope.etat = "form"

    $scope.ok = ->
      $scope.etat = "confirm"

    $scope.confirm = ->
      if $scope._errors?
        delete $scope._errors.localisation
      payload = $scope.localisation
      payload['date_maj'] = moment().utc()
      Backend.one("/usagers/#{usager.id}").customPOST(payload, "localisations", null, {"if-match": usager._version}).then(
        () ->
          $scope.etat = "success"
        (error) ->
          if error.status == 412
            $scope._errors =
              localisation: "Echec de la sauvegarde de l'adresse. Le document a été modifié par un autre utilisateur entre temps."
          else
            $scope._errors =
              localisation: error.data
          $scope.etat = "form"
      )

    $scope.success = ->
      $modalInstance.close(true)

    $scope.cancel = ->
      $modalInstance.close(false)
