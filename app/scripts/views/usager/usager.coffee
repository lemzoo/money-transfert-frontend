'use strict'

breadcrumbsGetUsagerDefer = undefined

compute_errors = (error) ->
  _errors = {}

  if typeof(error) == 'object'
    for key, value of error
      if key in ['nom', 'nom_usage', 'nom_pere', 'nom_mere',
                 'prenom_pere', 'prenom_mere', 'representant_legal_nom', 'representant_legal_prenom']
        if value in ['String value did not match validation regex', 'String value is too long']
          _errors[key] = "Ce champ accepte les lettres, les tirets et les apostrophes. Ces deux caractères spéciaux ne doivent figurer ni en début ni en fin de mot. Ce champ est limité à 30 caractères."
        else if typeof(value) == 'object'
          _errors[key] = 'Champ requis.'
        else
          _errors[key] = value

      else if key == 'email'
        _errors[key] = "Adresse email invalide"

      else if key == 'telephone'
        if value == 'String value did not match validation regex'
          _errors[key] = 'Le numéro de téléphone doit être composé de chiffres et d\'espace. Il peut commencer par un +'
        else
          _errors[key] = value

      else if key == 'prenoms'
        msg = ''
        if typeof(value) == 'object'
          for index, prenom_error of value
            # true_index = parseInt(index) + 1
            tmp_msg = '\n'
            msg += tmp_msg
            if prenom_error in ['String value did not match validation regex', 'String value is too long']
              tmp_msg = "Ce champ accepte les lettres, les tirets et les apostrophes. Ces deux caractères spéciaux ne doivent figurer ni en début ni en fin de mot. Ce champ est limité à 30 caractères."
              msg += tmp_msg
              break
          _errors[key] = msg
        else if value == 'Field is required and cannot be empty'
          _errors[key] = 'Champ requis.'
        else
          _errors[key] = value

      else if key == 'pays_traverses'
        if typeof(value) == "object"
          msg = ''
          for index, pays_traverses_error of value
            if index == 'pays'
              msg += "Les pays sont obligatoires.\n"
            else
              true_index = parseInt(index)+1
              tmp_msg = "Pays n°#{true_index}: "
              if typeof(pays_traverses_error) == 'object'
                for fieldIndex, fieldError of pays_traverses_error
                  tmp_msg += "#{fieldIndex}: #{fieldError}\n"
              else
                tmp_msg += "#{pays_traverses_error}\n"
              msg += tmp_msg
          _errors[key] = msg
        else
          _errors[key] = value

      else
        if typeof(value) == 'object'
          _errors[key] = 'Champ requis.'
        else if value == 'Field is required' or value == 'Field may not be null.' or value == 'Field is required and cannot be empty'
          _errors[key] = 'Champ requis.'
        else
          _errors[key] = value
  else
    _errors['usager_info'] = error
    return _errors
  return _errors

initWorkingScope = (scope, $modal) ->
  scope.working = false
  scope.saveDone = {}
  scope.transfertDone = {}
  scope.addressDone = {}
  scope.workingModal = ->
    modalInstance = $modal.open(
      templateUrl: 'scripts/xin/modal/modal.html'
      controller: 'ModalInstanceAlertController'
      resolve:
        message: -> return "Un traitement est en cours."
    )


angular.module('app.views.usager', ['app.settings', 'ngRoute', 'ui.bootstrap',
                                    'xin.listResource', 'xin.tools',
                                    'xin.session', 'xin.backend',
                                    'xin.referential', 'xin.usager',
                                    'app.views.usager.modal'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/usagers',
        templateUrl: 'scripts/views/usager/list_usagers.html'
        controller: 'ListUsagersController'
        breadcrumbs: 'Usagers'
        reloadOnSearch: false
        routeAccess: true,
      .when '/usagers/:usagerId',
        templateUrl: 'scripts/views/usager/show_usager.html'
        controller: 'ShowUsagerController'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetUsagerDefer = $q.defer()
          breadcrumbsGetUsagerDefer.promise.then (usager) ->
            breadcrumbsDefer.resolve([
              ['Usagers', '#/usagers']
              [usager.id, '#/usagers/' + usager.id]
            ])
          return breadcrumbsDefer.promise


  .controller 'ListUsagersController', ($scope, $route, $routeParams,
                                        session, Backend, DelayedEvent, SETTINGS) ->
    $scope.lookup =
      per_page: "12"
      page: "1"
    $scope.site_affecte =
      id: null
      sans_limite: false
    $scope.links = null

    $scope.toggle =
      show: true
      overall: $routeParams.overall?
      left_label: "Globale"
      right_label: "Locale"

    $scope.$watch 'toggle.overall', (value, old_value) ->
      if old_value? and value != old_value
        window.location = "#/usagers#{if value then '?overall' else ''}"

    session.getUserPromise().then(
      (user) ->
        if user.site_affecte?
          $scope.site_affecte.id = user.site_affecte.id
        else if user.role in ["SUPPORT_NATIONAL", "GESTIONNAIRE_NATIONAL"]
          $scope.site_affecte.sans_limite = true
          $scope.toggle.show = false
        else
          return
        route = if $scope.toggle.overall then 'usagers?overall' else 'usagers'
        $scope.resourceBackend = Backend.all(route)
    )


  .controller 'ShowUsagerController', ($scope, $route, $routeParams, $filter, moment
                                       $modal, Backend, BackendWithoutInterceptor,
                                       session, SETTINGS) ->
    initWorkingScope($scope, $modal)
    usagerResource = {}
    $scope.usager = {}
    $scope.origin_usager = {}
    $scope.PERMISSIONS = SETTINGS.PERMISSIONS

    session.getUserPromise().then (user) ->
      $scope.user = user.plain()
      $scope.canModifierUser = not $routeParams.overall? and 'modifier_usager' in $scope.PERMISSIONS[user.role]

    # Use to know if we are on overall or local view
    url_overall = if $routeParams.overall? then {'overall': true} else {}
    Backend.one('usagers', $routeParams.usagerId).get(url_overall).then (usager) ->
      # breadcrums
      if breadcrumbsGetUsagerDefer?
        breadcrumbsGetUsagerDefer.resolve(usager)
        breadcrumbsGetUsagerDefer = undefined
      usagerResource = usager
      $scope.usager = usager.plain()
      angular.copy($scope.usager, $scope.origin_usager)

    makePayload = ->
      fields = ["origine_nom", "origine_nom_usage", "nom_pere", "prenom_pere",
                "nom_mere", "prenom_mere", "langues", "langues_audition_OFPRA",
                "representant_legal_nom", "representant_legal_prenom",
                "representant_legal_personne_morale", "representant_legal_personne_morale_designation",
                "telephone", "email", "date_deces"]
      payload = {}
      for field in fields
        if not $scope.usager[field] and not $scope.origin_usager[field]
          continue
        else if not angular.equals($scope.usager[field], $scope.origin_usager[field])
          payload[field] = $scope.usager[field] or null
      if Object.keys(payload).length
        return payload
      return null

    patchUsager = (payload) ->
      usagerResource.patch(payload, null, {"if-match": usagerResource._version}).then(
        (usager) ->
          usagerResource._version = usager._version
          payload = makePayloadEtatCivil()
          if payload?
            patchEtatCivil(payload, true)
          else
            displayModalSaved()
        (error) ->
          manageErrors(error)
      )

    makePayloadEtatCivil = ->
      fields = ["nom", "nom_usage", "prenoms", "photo", "sexe",
                "date_naissance", "date_naissance_approximative",
                "ville_naissance", "pays_naissance",
                "nationalites", "situation_familiale"]
      payload = {}
      for field in fields
        if not $scope.usager[field] and not $scope.origin_usager[field]
          continue
        else if not angular.equals($scope.usager[field], $scope.origin_usager[field])
          payload[field] = $scope.usager[field] or null
      if Object.keys(payload).length
        return payload
      return null

    patchEtatCivil = (payload, firstPatchSuccess = false) ->
      usagerResource.customOperation("patch", "etat_civil", null, {"if-match" : usagerResource._version}, payload).then(
        () ->
          displayModalSaved()
        (error) ->
          manageErrors(error, firstPatchSuccess)
      )

    displayModalConfirm = (patch, payload) ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: () ->
            return "Valider les modifications de l'usager?"
          sub_message: () ->
            return ""
      )
      modalInstance.result.then (result) ->
        if not result
          $scope.saveDone.end?()
          return
        if patch == "usager"
          patchUsager(payload)
        else if patch == "etat_civil"
          patchEtatCivil(payload)

    displayModalSaved = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceForceConfirmController'
        keyboard: false
        backdrop: false
        resolve:
          message: () ->
            return "L'usager a bien été modifié."
          sub_message: () ->
            return ""
      )
      modalInstance.result.then (result) ->
        $route.reload()

    manageErrors = (error, firstPatchSuccess = false) ->
      if error.status == 412
        $scope.usager._errors._error = "La sauvegarde des modifications est impossible, cet usager a été modifié entre-temps par un autre utilisateur."
      else
        data = error.data
        $scope.usager._errors = compute_errors(data)
        $scope.usager._errors._error = "Impossible de sauvegarder l'usager."
        if firstPatchSuccess
          $scope.usager._errors._error = "Sauvegarde partiel de l'usager. Les champs suivants ont été sauvegardés:"
          $scope.usager._errors._error += " Origine du nom,"
          $scope.usager._errors._error += " Origine du nom d'usage,"
          $scope.usager._errors._error += " Nom du père,"
          $scope.usager._errors._error += " Prénom du père,"
          $scope.usager._errors._error += " Nom de la mère,"
          $scope.usager._errors._error += " Prénom de la mère,"
          $scope.usager._errors._error += " Langues,"
          $scope.usager._errors._error += " Langue d'audition OFPRA,"
          $scope.usager._errors._error += " Représentant légal si mineur,"
          $scope.usager._errors._error += " Téléhpone,"
          $scope.usager._errors._error += " Email."
      $scope.saveDone.end?()

    $scope.save = ->
      $scope.usager._errors = {}
      payload = makePayload()
      if payload?
        displayModalConfirm('usager', payload)
      else
        payload = makePayloadEtatCivil()
        if payload?
          displayModalConfirm('etat_civil', payload)
        else
          $scope.usager._errors._error = "Aucune donnée n'a été modifiée."
          $scope.saveDone.end?()

    $scope.relocate = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/usager/modal/relocate.html'
        controller: 'ModalRelocateUsagerController'
        keyboard: false
        backdrop: false
        resolve:
          usager: ->
            return usagerResource
      )
      modalInstance.result.then (answer) ->
        if answer
          window.location = '#/usagers'
        else
          $scope.transfertDone.end?()

    $scope.changeAddress = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/usager/modal/address.html'
        controller: 'ModalChangeAddressController'
        keyboard: false
        backdrop: false
        resolve:
          usager: ->
            return usagerResource
      )
      modalInstance.result.then (answer) ->
        if answer
          $route.reload()
        else
          $scope.addressDone.end?()
