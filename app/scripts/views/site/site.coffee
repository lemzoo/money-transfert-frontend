'use strict'

breadcrumbsGetSiteDefer = undefined

compute_errors = (error) ->
  _errors = {}

  if error.status == 412
    _errors['text'] = "La sauvegarde des modifications est impossible, ce site a été modifié entre-temps par un autre utilisateur."
  else
    _errors['text'] = "Le site n'a pas pu être sauvegardé."

  for key, value of error.data
    if key == '_errors'
      if value[0]['adresse']
        _errors['adresse'] = 'Information(s) manquante(s):'
        for elt_key, elt_value of value[0]['adresse']
          _errors['adresse'] += "#{elt_key} "
      else if value[0].indexOf("Tried to save duplicate unique keys") > -1
        _errors['libelle'] = 'Ce libellé de site existe déjà dans la base de données.'
      else
        _errors['libelle'] = value[0]
    else if key == 'libelle'
      if "Field may not be null." in value
        _errors[key] = "Ce champ est requis."
    else if key == 'adresse'
      if "Missing data for required field." in value
        _errors[key] = 'Informations manquantes'
    else if key == 'autorite_rattachement'
      if "Missing data for required field." in value
        _errors[key] = 'Choisir une autorité de rattachement'
    else if key == 'telephone'
      if value == 'String value did not match validation regex'
        _errors[key] = 'Le numéro de téléphone doit être composé de chiffres et d\'espace. Il peut commencer par un +'
      else
        _errors[key] = value
    else if key == 'email'
      if value.indexOf('Invalid Mail-address:') > -1
        _errors[key] = 'Adresse email invalide'
      else
        _errors[key] = value
    else if key == 'code_departement'
      if value.indexOf('String value did not match validation regex') > -1
        _errors[key] = 'Ce champs doit être composé de trois chiffres et se terminer par 0 ou 1.'
      else if value.indexOf('Missing data for required field.') > -1
        _errors[key] = 'Ce champs est requis.'
      else
        _errors[key] = value
    else
      if value == "Field is required"
        _errors[key] = 'Ce champ est requis'
      else if value == "Field is required and cannot be empty"
        _errors[key] = 'Ce champ est requis et ne peut être vide'
      else
        _errors[key] = value

  return _errors


initWorkingScope = (scope, $modal) ->
  scope.working = false
  scope.saveDone = {}
  scope.closeDone = {}
  scope.workingModal = ->
    modalInstance = $modal.open(
      templateUrl: 'scripts/xin/modal/modal.html'
      controller: 'ModalInstanceAlertController'
      resolve:
        message: -> return "Un traitement est en cours."
    )



angular.module('app.views.site', ['app.settings', 'ngRoute', 'ui.bootstrap',
                                  'xin.listResource', 'xin.tools', 'angularMoment',
                                  'xin.session', 'xin.backend', 'xin.modal',
                                  'xin.location', 'app.views.site.modal', 'angular-bootstrap-select'])

  .config ($routeProvider) ->
    $routeProvider
      .when '/sites',
        templateUrl: 'scripts/views/site/list_sites.html'
        controller: 'ListSitesController'
        breadcrumbs: 'Sites'
        reloadOnSearch: false
        routeAccess: true,
      .when '/sites/nouveau-site',
        templateUrl: 'scripts/views/site/show_site.html'
        controller: 'CreateSiteController'
        breadcrumbs: [['Sites', '#/sites'], ['Nouveau site']]
      .when '/sites/:siteId',
        templateUrl: 'scripts/views/site/show_site.html'
        controller: 'ShowSiteController'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetSiteDefer = $q.defer()
          breadcrumbsGetSiteDefer.promise.then (site) ->
            breadcrumbsDefer.resolve([
              ['Sites', '#/sites']
              [site.libelle, '#/sites/' + site.id]
            ])
          return breadcrumbsDefer.promise



  .controller 'ListSitesController', ($scope, Backend) ->
    $scope.links = null
    $scope.lookup =
      per_page: "12"
      page: "1"
    $scope.resourceBackend = Backend.all('sites')
    $scope.computeResource = (current_scope) ->
      for resource in current_scope.resources
        resource.already_inactive = false
        resource.soon_inactive = false

        if resource.date_fermeture?
          moment_today = moment()
          moment_inactive = moment(resource.date_fermeture)
          if moment_today > moment_inactive
            resource.already_inactive = true
          else
            resource.soon_inactive = true

    $scope.dtLoadingTemplate = ->
      return {
        html: '<img src="images/spinner.gif">'
      }



  .controller 'ShowSiteController', ($scope, $route, $routeParams,
                                     $modal, Backend, session, SETTINGS, moment) ->
    initWorkingScope($scope, $modal)
    $scope.site = {}
    $scope.structure_accueil = {}
    $scope.isEditable = false

    $scope.canModifierSite = false
    session.can('modifier_site').then () ->
      $scope.canModifierSite = true

    $scope.canFermerSite = false
    session.can('fermer_site').then () ->
      $scope.canFermerSite = true

    $scope.settingsSite = SETTINGS.SITES

    # types site
    $scope.typesSite = []
    for value, text of SETTINGS.SITES
      $scope.typesSite.push({id: value, libelle: text})

    # GUs + Pref
    $scope.guichets_uniques = []
    $scope.prefectures = []
    Backend.all('sites').getList().then (sites) ->
      for site in sites
        optionSite = {'value': site.id, 'text': site.type + ' - ' + site.libelle}
        if site.type == 'GU'
          $scope.guichets_uniques.push(optionSite)
        if site.type == 'Prefecture'
          $scope.prefectures.push(optionSite)

    $scope.site_inactif = false

    Backend.one('sites', $routeParams.siteId).get().then(
      (site) ->
        # breadcrums
        if breadcrumbsGetSiteDefer?
          breadcrumbsGetSiteDefer.resolve(site)
          breadcrumbsGetSiteDefer = undefined
        #

        if site.date_fermeture
          now = moment()
          date_fermeture = moment(site.date_fermeture)
          if date_fermeture < now
            $scope.site_inactif = true

        $scope.site = site
        if $scope.site.guichets_uniques?
          ids = []
          for gu in $scope.site.guichets_uniques
            ids.push(gu.id)
          $scope.site.guichets_uniques = ids

        if $scope.site.prefectures?
          ids = []
          for pref in $scope.site.prefectures
            ids.push(pref.id)
          $scope.site.prefectures = ids

        $scope.origin_site =
          type: site.type
          email: site.email
          libelle: site.libelle
          telephone: site.telephone
          guichets_uniques: site.guichets_uniques
          autorite_rattachement: site.autorite_rattachement
          prefectures: site.prefectures

      (error) -> window.location = '#/404'
    )


    $scope.closeSite = ->
      if $scope.working
        $scope.workingModal()
        return
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/site/modal/close_site.html'
        controller: 'ModalInstanceCloseSiteController'
        backdrop: false
        keyboard: false
        resolve:
          site: ->
            return { libelle: $scope.site.libelle }
      )
      modalInstance.result.then (date_fermeture) ->
        if date_fermeture
          $scope.working = true
          Backend.one('sites/'+$scope.site.id)
            .patch({date_fermeture: date_fermeture}, null, {'if-match': $scope.site._version}).then(
              -> $route.reload()
              (error) ->
                $scope.closeDone.end?()
                $scope.working = false
                throw error
            )
        else
          $scope.closeDone.end?()


    $scope.reopenSite = ->
      if $scope.working
        $scope.workingModal()
        return
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return "Vous vous apprêtez à réouvrir ce site"
          sub_message: ->
            return ''
      )
      modalInstance.result.then (result) ->
        if result
          $scope.working = true
          Backend.one('sites/'+$scope.site.id)
            .patch({date_fermeture: null}, null, {'if-match': $scope.site._version}).then(
              -> $route.reload()
              (error) ->
                $scope.closeDone.end?()
                $scope.working = false
                throw error
            )
        else
          $scope.closeDone.end?()


    $scope.saveSite = ->
      if $scope.working
        $scope.workingModal()
        return
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/site/modal/confirm_edit_site.html'
        controller: 'ModalInstanceConfirmNewSiteController'
        backdrop: false
        keyboard: false
        resolve:
          site: ->
            return { libelle: $scope.site.libelle }
      )
      modalInstance.result.then (answer) ->
        if answer
          $scope.working = true
          # Retrieve the modified fields from the form
          payload = {}

          for key, value of $scope.siteForm
            if key.charAt(0) != '$'
              if key == 'code_departement'
                continue
              if $scope.site[key] == '' or $scope.site[key] == undefined
                payload[key] = null
              else
                payload[key] = $scope.site[key]

          # Localisation
          if $scope.site.adresse?
            payload.adresse = $scope.site.adresse
          # If StructureAccueil
          if $scope.site.type == 'StructureAccueil'
            payload.guichets_uniques = $scope.site.guichets_uniques
          # If autorite_rattachement
          if $scope.site.type == 'GU'
            payload.autorite_rattachement = $scope.site.autorite_rattachement.id
          if $scope.site.type == 'Prefecture'
            payload.code_departement = $scope.site.code_departement
          if $scope.site.type == 'EnsembleZonal'
            payload.prefectures = $scope.site.prefectures

          # Send POST
          Backend.all('sites/'+$scope.site.id).patch(payload, null, {'if-match': $scope.site._version}).then(
            (site) ->
              modalInstance = $modal.open(
                templateUrl: 'scripts/views/site/modal/site_edited.html'
                controller: 'ModalInstanceSiteCreatedController'
                backdrop: false
                keyboard: false
                resolve:
                  site: ->
                    return { libelle: $scope.site.libelle }
              )
              modalInstance.result.then((action) ->
                if action == 'list'
                  window.location = '#/sites'
                else
                  $route.reload()
              )
            (error) ->
              $scope.error = compute_errors(error)
              $scope.working = false
              $scope.saveDone.end?()
          )
        else
          # modal canceled
          $scope.saveDone.end?()



  .controller 'CreateSiteController', ($scope, $route, $routeParams,
                                     $modal, Backend, session, SETTINGS) ->
    initWorkingScope($scope, $modal)
    $scope.site =
      autorite_rattachement: {}
    $scope.creation = true

    $scope.canModifierSite = false
    session.can('modifier_site').then ()->
      $scope.canModifierSite = true

    $scope.canFermerSite = false
    session.can('fermer_site').then ()->
      $scope.canFermerSite = true

    $scope.settingsSite = SETTINGS.SITES
    # types site
    $scope.typesSite = []
    for value, text of SETTINGS.SITES
      $scope.typesSite.push({id: value, libelle: text})


    $scope.saveSite = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/site/modal/confirm_new_site.html'
        controller: 'ModalInstanceConfirmNewSiteController'
        backdrop: false
        keyboard: false
        resolve:
          site: ->
            return { libelle: $scope.site.libelle }
      )
      modalInstance.result.then (answer) ->
        if answer
          # Retrieve the modified fields from the form
          payload = {}
          for key, value of $scope.siteForm
            if key == 'code_departement'
              continue
            if key.charAt(0) != '$'
              if $scope.site[key] == '' or $scope.site[key] == undefined
                payload[key] = null
              else
                payload[key] = $scope.site[key]

          # Type
          if $scope.site.type?
            payload.type = $scope.site.type
          # Localisation
          if $scope.site.adresse?
            payload.adresse = $scope.site.adresse
          # If StructureAccueil
          if $scope.site.type == 'StructureAccueil'
            payload.guichets_uniques = $scope.site.guichets_uniques
          # If autorite_rattachement
          if $scope.site.type == 'GU'
            payload.autorite_rattachement = $scope.site.autorite_rattachement.id
          if $scope.site.type == 'Prefecture'
            payload.code_departement = $scope.site.code_departement
          if $scope.site.type == 'EnsembleZonal'
            payload.prefectures = $scope.site.prefectures

          # Send POST
          Backend.all('sites').post(payload).then(
            (site) ->
              modalInstance = $modal.open(
                templateUrl: 'scripts/views/site/modal/site_created.html'
                controller: 'ModalInstanceSiteCreatedController'
                backdrop: false
                keyboard: false
                resolve:
                  site: ->
                    return { libelle: $scope.site.libelle }
              )
              modalInstance.result.then((action) ->
                if action == 'list'
                  window.location = '#/sites'
                else
                  window.location = '#/sites/'+site.id
              )
            (error) ->
              $scope.error = compute_errors(error)
              $scope.saveDone.end?()
          )
        else
          # modal canceled
          $scope.saveDone.end?()
