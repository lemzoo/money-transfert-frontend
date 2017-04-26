'use strict'

breadcrumbsGetUtilisateurDefer = undefined

compute_errors = (error) ->
  _errors = {}

  if error.status == 412
    _errors['text'] = "La sauvegarde des modifications est impossible, cet utilisateur a été modifié entre-temps par un autre utilisateur."
  else
    _errors['text'] = "L'utilisateur n'a pas pu être sauvegardé."

    for key, value of error.data
      if key == '_errors' and value[0].indexOf("Tried to save duplicate unique keys") > -1
        _errors['email'] = 'Cet email existe déjà dans la base de données.'
      else if key == 'email'
        if value.indexOf('Invalid Mail-address:') > -1
          _errors[key] = 'Adresse email invalide'
        else if value == 'Field is required' or 'Field may not be null.' in value
          _errors[key] = 'Ce champ est requis'
        else
          _errors[key] = value
      else if key == 'telephone'
        if value == 'String value did not match validation regex'
          _errors[key] = 'Le numéro de téléphone doit être composé de chiffres et d\'espace. Il peut commencer par un +'
        else
          _errors[key] = value
      else if key == 'prenom' or key == 'nom'
        if value == 'Field is required' or 'Field may not be null.' in value
          _errors[key] = 'Ce champ est requis'
        else if value == 'String value did not match validation regex'
          _errors[key] = "Contient des lettes et/ou - ' ces 2 caractères spéciaux ne doivent figurer ni en début ni en fin de mot."
        else
          _errors[key] = value
      else if key == 'role'
        if ['un utilisateur ADMINISTRATEUR_PREFECTURE ne peut pas assigner un role None', 'un utilisateur ADMINISTRATEUR_PA ne peut pas assigner un role None', 'un utilisateur ADMINISTRATEUR_NATIONAL ne peut pas assigner un role None'].indexOf(value) > -1
          _errors[key] = "Champ requis"
        else if value.indexOf('Not a valid choice.') > -1
          _errors[key] = "Champ requis"
      else if key == 'site'
        if value == 'un utilisateur None n\'a pas de site assigné'
          continue
        else if ['un utilisateur ADMINISTRATEUR_PREFECTURE est assign\u00e9 \u00e0 un site Site.Prefecture', 'un utilisateur RESPONSABLE_ZONAL est assign\u00e9 \u00e0 un site Site.EnsembleZonal', "un utilisateur %s avoir site rattach\u00e9 \u00e0 la pr\u00e9fecture de son cr\u00e9ateur"].indexOf(value) > -1
          _errors[key] = "Champ requis"
      else
        if value == 'Field is required' or value == 'Field may not be null.'
          _errors[key] = 'Ce champ est requis'
        else
          if value == 'Field is required' then _errors[key] = 'Ce champ est requis' else _errors[key] = value

  return _errors


compute_accr_errors = (error) ->
  _errors = {}
  for key, value of error
    if ['site', 'role'].indexOf(key) > -1
      _errors[key] = 'Ce champ est requis'
    else
      _errors['site'] = value
  return _errors

initWorkingScope = (scope, $modal) ->
  scope.working = false
  scope.saveDone = {}
  scope.activeDone = {}
  scope.passwordDone = {}
  scope.workingModal = ->
    modalInstance = $modal.open(
      templateUrl: 'scripts/xin/modal/modal.html'
      controller: 'ModalInstanceAlertController'
      resolve:
        message: -> return "Un traitement est en cours."
    )


createEmptyAccreditation = -> {
  mode: 'create'
  data: {'role': '', 'site_affecte': undefined, 'fin_validite': undefined}
  originalData: ''
}

angular.module('app.views.utilisateur', ['app.settings', 'ngRoute', 'ui.bootstrap',
                                         'xin.listResource', 'xin.solrFilters', 'xin.tools',
                                         'xin.session', 'xin.backend', 'angularMoment',
                                         'app.views.utilisateur.modal', 'xin.habilitations',
                                         'angular-bootstrap-select', 'xin.form'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/utilisateurs',
        templateUrl: 'scripts/views/utilisateur/list_utilisateurs.html'
        controller: 'ListUtilisateursController'
        breadcrumbs: 'Utilisateurs'
        reloadOnSearch: false
        routeAccess: true,
      .when '/utilisateurs/nouvel-utilisateur',
        templateUrl: 'scripts/views/utilisateur/show_utilisateur.html'
        controller: 'CreateUtilisateurController'
        breadcrumbs: [['Utilisateurs', '#/utilisateurs'], ['Nouvel utilisateur']]
        routeAccess: true,
      .when '/utilisateurs/:userId',
        templateUrl: 'scripts/views/utilisateur/show_utilisateur.html'
        controller: 'ShowUtilisateurController'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetUtilisateurDefer = $q.defer()
          breadcrumbsGetUtilisateurDefer.promise.then (utilisateur) ->
            breadcrumbsDefer.resolve([
              ['Utilisateurs', '#/utilisateurs']
              [utilisateur.prenom + ' ' + utilisateur.nom, '#/utilisateurs/' + utilisateur._id]
            ])
          return breadcrumbsDefer.promise


  .controller 'ListUtilisateursController', ($scope, $route, $routeParams, Backend,
                                             ADMINISTRATEUR_NATIONAL_CREATES_ROLES, session, moment) ->
    $scope.lookup =
      per_page: "12"
      page: "1"

    $scope.toggle =
      show: true
      overall: $routeParams.overall?
      left_label: "Globale"
      right_label: "Locale"

    $scope.$watch 'toggle.overall', (value, old_value) ->
      if old_value? and value != old_value
        window.location = "#/utilisateurs#{if value then '?overall' else ''}"

    session.getUserPromise().then(
      (user) ->
        #toggle disabled for support national et administrateur
        $scope.toggle.show = user.role not in ['SUPPORT_NATIONAL', 'ADMINISTRATEUR']
        # toggle label=Nationale instead of Locale for ADMINISTRATEUR_NATIONAL
        if user.role == 'ADMINISTRATEUR_NATIONAL'
          $scope.toggle.right_label = "Nationale"


        route = "utilisateurs"
        if $scope.toggle.overall
          route = route + "?overall"
          # INIT: Remove these lines with new authentification
          # Remove system account into global view (Admins locaux)
          if ['ADMINISTRATEUR_PA', 'ADMINISTRATEUR_PREFECTURE', 'ADMINISTRATEUR_DT_OFII'].indexOf(user.role) > -1
            route = route + "&fq=-accreditations_role_ss:(#{['SYSTEME_INEREC', 'SYSTEME_AGDREF', 'SYSTEME_DNA'].join(" OR ")})"
          # END
        else if user.role == 'ADMINISTRATEUR_NATIONAL'
          route = route + "?fq=accreditations_role_ss:(#{ADMINISTRATEUR_NATIONAL_CREATES_ROLES.join(" OR ")})"
        $scope.resourceBackend = Backend.all(route)
    )
    $scope.links = null

    $scope.computeResource = (current_scope) ->
      for resource in current_scope.resources
        resource.already_inactive = false
        resource.soon_inactive = false

        if resource.fin_validite?
          moment_today = moment()
          moment_inactive = moment(resource.fin_validite)
          if moment_today > moment_inactive
            resource.already_inactive = true
          else
            resource.soon_inactive = true

    $scope.dtLoadingTemplate = ->
      return {
        html: '<img src="images/spinner.gif">'
      }



  .controller 'ShowUtilisateurController', ($q, $scope, $route, $routeParams, moment,
                                            $modal, Backend, session, SETTINGS, DelayedEvent) ->
    initWorkingScope($scope, $modal)
    $scope.utilisateur = {}
    $scope.accreditations = []
    userBackend = undefined
    $scope.canModifierUtilisateur = false
    $scope.isMyProfile = false
    if $routeParams.userId == 'moi'
      route = 'moi'
      $scope.isMyProfile = true
      $scope.isRouteMoi = true
    else
      route = 'utilisateurs/' + $routeParams.userId
      $scope.isRouteMoi = false
      session.getUserPromise().then (user) ->
        $scope.isMyProfile = ($routeParams.userId == user.id)
        if not $scope.isMyProfile
          session.can('modifier_utilisateur').then ->
            $scope.canModifierUtilisateur = true


    # Use to know if we are on overall or local view
    url_overall = if $routeParams.overall? then '?overall' else ''

    $scope.sites_url = 'sites'
    $scope.sites_label = 'Choisissez un site'
    $scope.utilisateur_inactif = false


    cookAccreditationsFromBackend = (data) ->
      accrs = []
      for rawAccr in data._items
        accr = {}
        accr.mode = "created"
        if rawAccr._links.update?
          accr.mode = "update"
        accr.id = rawAccr.id
        accr.data = {'role': rawAccr.role, 'fin_validite': rawAccr.fin_validite}
        if rawAccr.site_affecte? and rawAccr.site_affecte.id? and rawAccr.site_affecte.id != ""
          accr.data.site_affecte = rawAccr.site_affecte.id
        accr.originalData = _.clone(accr.data)
        accrs.push accr
      return accrs


    Backend.one("#{route}#{url_overall}").get().then(
      (utilisateur) ->
        Backend.one(route + '/accreditations').get().then(
          (accreditations) ->
            # breadcrums
            if breadcrumbsGetUtilisateurDefer?
              breadcrumbsGetUtilisateurDefer.resolve(utilisateur)
              breadcrumbsGetUtilisateurDefer = undefined

            $scope.utilisateur = utilisateur

            if utilisateur.fin_validite
              now = moment()
              fin_validite = moment(utilisateur.fin_validite)
              if fin_validite < now
                $scope.utilisateur_inactif = true

            $scope.origin_utilisateur =
              email: utilisateur.email
              prenom: utilisateur.prenom
              nom: utilisateur.nom
              telephone: utilisateur.telephone

            $scope.accreditations = cookAccreditationsFromBackend(accreditations)

          (error) -> window.location = '#/404'
        )

      (error) -> window.location = '#/404'
    )


    $scope.addAccreditation = () ->
      $scope.accreditations.push createEmptyAccreditation()

    $scope.deleteAccreditation = (index) ->
      $scope.accreditations.splice index, 1

    $scope.activateAccreditation = (accr) ->
      confirmModalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return "Confirmez-vous l'activation de cette habilitation"
          sub_message: ->
            return ""
      )
      confirmModalInstance.result.then (answer) ->
        if answer
          $scope.working = true
          Backend.all(route + "/accreditations/#{accr.id}").patch({fin_validite: null}, null, {'if-match' : $scope.utilisateur._version}).then(
            -> $route.reload()
            (error) ->
              $scope.working = false
              $scope._errors = { "text": "L'utilisateur n'a pas pu être sauvegardé. Problème au niveau des habilitations." }
              accr._errors = compute_accr_errors(error.data)
          )


    $scope.deactivateAccreditation = (accr) ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/utilisateur/modal/deactivate_user.html'
        controller: 'ModalInstanceDeactivateController'
        backdrop: false
        keyboard: false
      )
      modalInstance.result.then (fin_validite) ->
        if fin_validite
          $scope.working = true
          Backend.all(route + "/accreditations/#{accr.id}").patch({fin_validite: fin_validite}, null, {'if-match' : $scope.utilisateur._version}).then(
            -> $route.reload()
            (error) ->
              $scope.working = false
              $scope._errors = { "text": "L'utilisateur n'a pas pu être sauvegardé. Problème au niveau des habilitations." }
              accr._errors = compute_accr_errors(error.data)
          )


    $scope.editPassword = ->
      if $scope.working
        $scope.workingModal()
        return
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/utilisateur/modal/edit_password.html'
        controller: 'ModalInstanceEditPasswordController'
        backdrop: false
        keyboard: false
        resolve:
          ownProfil: -> return $scope.isMyProfile
          utilisateur: -> return $scope.utilisateur
      )
      modalInstance.result.then (token) ->
        if token != false
          if token != ""
            session.login(token)
          $route.reload()
        else
          $scope.passwordDone.end?()


    $scope.saveUser = ->
      if $scope.working
        $scope.workingModal()
        return
      confirmModalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return "Confirmez-vous la modification de l'utilisateur #{$scope.utilisateur.prenom} #{$scope.utilisateur.nom}"
          sub_message: ->
            return ""
      )
      confirmModalInstance.result.then (answer) ->
        if answer
          $scope.working = true
          payload = {}
          # Retrieve the modified fields from the form
          for key, value of $scope.userForm
            if key.charAt(0) != '$'
              if $scope.utilisateur[key] == '' or $scope.utilisateur[key] == undefined
                payload[key] = null
              else
                payload[key] = $scope.utilisateur[key]

          # Update current information (firstname / lastname / email / phone)
          Backend.one("#{route}#{url_overall}").patch(payload, null, {'if-match' : $scope.utilisateur._version}).then(
            (user) ->
              # Save accreditations
              saveAccreditationsLoop = (index) ->
                if index >= 0
                  accr = $scope.accreditations[index]
                  if accr.mode == 'create'
                    # Remove if backend retur utilisateur and no more new/updated accreditation
                    $scope.utilisateur._version = $scope.utilisateur._version + 1
                    Backend.all(route + "/accreditations").post(accr.data).then(
                      (accreditation) ->
                        accr.id = accreditation.id
                        accr.mode = 'update'
                        saveAccreditationsLoop(index - 1)
                      (error) ->
                        $scope._errors = { "text": "L'utilisateur n'a pas pu être sauvegardé. Problème au niveau des habilitations." }
                        accr._errors = compute_accr_errors(error.data)
                        $scope.saveDone.end?()
                        $scope.working = false
                    )
                  else
                    saveAccreditationsLoop(index - 1)
                else
                  # No more accreditations, show modal or reload page
                  if route == 'moi'
                    $route.reload()
                  else
                    modalInstance = $modal.open(
                      templateUrl: 'scripts/views/utilisateur/modal/user_edited.html'
                      controller: 'ModalInstanceUserCreatedController'
                      resolve:
                        user: ->
                          return {nom: user.nom, prenom: user.prenom}
                    )
                    modalInstance.result.then((action) ->
                      if action == 'list'
                        window.location = '#/utilisateurs'
                      else if action == 'show'
                        $route.reload()
                    )
              # Run save Accreditations loop
              saveAccreditationsLoop($scope.accreditations.length - 1)

            (error) ->
              $scope._errors = compute_errors(error)
              $scope.saveDone.end?()
              $scope.working = false
          )
        else
          # modal canceled
          $scope.saveDone.end?()



  .controller 'CreateUtilisateurController', ($scope, $route, $routeParams,
                                              $modal, Backend, session, SETTINGS, DelayedEvent) ->
    initWorkingScope($scope, $modal)
    $scope.utilisateur = {}
    $scope.accreditations = [createEmptyAccreditation()]
    $scope.creation = true

    $scope.sites_label = 'Choisissez un site'
    $scope.sites_url = 'sites'

    $scope.canModifierUtilisateur = false
    session.can('modifier_utilisateur').then ()->
      $scope.canModifierUtilisateur = true


    $scope.addAccreditation = () ->
      $scope.accreditations.push createEmptyAccreditation()


    $scope.deleteAccreditation = (index) ->
      $scope.accreditations.splice index, 1


    $scope.saveUser = ->
      confirmModalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return "Confirmez-vous la création de l'utilisateur #{$scope.utilisateur.prenom} #{$scope.utilisateur.nom}"
          sub_message: ->
            return ""
      )
      confirmModalInstance.result.then (answer) ->
        if answer
          userPayload = {}
          # Retrieve the modified fields from the form
          for key, value of $scope.userForm
            if key.charAt(0) != '$'
              if $scope.utilisateur[key] == '' or $scope.utilisateur[key] == undefined
                userPayload[key] = null
              else
                userPayload[key] = $scope.utilisateur[key]

          # Accreditations fields
          userPayload.accreditations = []
          for accr in $scope.accreditations
            userPayload.accreditations.push(accr.data)

          # Save new utilisateur
          Backend.all('utilisateurs').post(userPayload).then(
            (user) ->
              modalInstance = $modal.open(
                templateUrl: 'scripts/views/utilisateur/modal/user_created.html'
                controller: 'ModalInstanceUserCreatedController'
                backdrop: false
                keyboard: false
                resolve:
                  user: ->
                    return { nom: user.nom, prenom: user.prenom }
              )
              modalInstance.result.then((action) ->
                if action == 'list'
                  window.location = '#/utilisateurs'
                else if action == 'show'
                  window.location = '#/utilisateurs/'+user.id
              )

            (error) ->
              for key, value of error.data['accreditations']
                $scope.accreditations[key]._errors = compute_accr_errors(value)
              $scope._errors = compute_errors(error)
              $scope.saveDone.end?()
          )
        else
          # modal canceled
          $scope.saveDone.end?()
