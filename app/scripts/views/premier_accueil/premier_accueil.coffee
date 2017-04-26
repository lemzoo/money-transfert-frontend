'use strict'

breadcrumbsGetRecueilDADefer = undefined


manage_errors = ($scope, error, compute_errors, action = "save") ->
  $scope.errors =
    _errors: []
  $scope.recueil_da._errors = {}

  if action == "save"
    $scope.errors._errors.push("Le recueil n'a pas pu être enregistré.")
  else if action == "validate"
    $scope.errors._errors.push("La prise de rendez-vous n'a pas pu être faite.")

  if error.status == 400
    if action == "save"
      $scope.errors._errors.push("Veuillez vérifier votre saisie.")
    for key, value of error.data
      if key == '_errors'
        for error in value
          if "L'utilisateur doit avoir un StructureAccueil comme site_affecte pour pouvoir créer un receuil_da" in value
            $scope.errors._errors.push("L'utilisateur doit être rattaché à une structure d'accueil pour pouvoir créer un recueil de demande d'asile")
          else
            $scope.errors._errors.push(error)
      else if key == 'usager_1'
        $scope.usager_1._errors = compute_errors(value, "Usager 1", $scope.errors._errors)
      else if key == 'usager_2'
        if value == "Un usager secondaire est requis en cas de situation familiale MARIE, CONCUBIN ou PACSE"
          $scope.errors._errors.push(value)
        else if value == "La situation familiale de l'usager principal doit être MARIE, CONCUBIN ou PACSE pour avoir un usager secondaire."
          if not $scope.usager_1._errors?
            $scope.usager_1._errors = {}
          $scope.usager_1._errors['situation_familiale'] = value
          $scope.errors._errors.push(value)
        else
          $scope.usager_2._errors = compute_errors(value, "Usager 2", $scope.errors._errors)
      else if key == 'enfants'
        for child_key, child_value of value
          if $scope.enfants[child_key]
            $scope.enfants[child_key]._errors = compute_errors(child_value, "Enfant #{parseInt(child_key)+1}", $scope.errors._errors)
          else
            $scope.errors._errors.push(child_value)
      else if key == 'profil_demande'
        $scope.errors._errors.push("Ajoutez au moins un usager demandeur.")
      else
        $scope.errors[key] = value

  else if error.status == 412
    $scope.errors._errors.push("La sauvegarde des modifications est impossible, ce recueil a été modifié entre-temps par un autre utilisateur.")
  else
    $scope.errors._errors.push("Une erreur interne est survenue. Merci de contacter votre administrateur")
  $scope.working = false
  $scope.saveDone.end?()


compute_profil_demande = (scope, recueil_da, is_minor) ->
  recueil_da.profil_demande = ''
  # determine if usager_1 is minor
  if scope.usager_1.demandeur and scope.usager_1.date_naissance
    if is_minor(scope.usager_1.date_naissance)
      recueil_da.profil_demande = 'MINEUR_ISOLE'
      return

  for enfant in scope.enfants
    if enfant.demandeur and enfant.date_naissance
      if is_minor(enfant.date_naissance)
        recueil_da.profil_demande = 'MINEUR_ACCOMPAGNANT'
        return

  has_usager_1 = false
  if scope.usager_1.demandeur || scope.usager_1.present_au_moment_de_la_demande
    has_usager_1 = true

  has_usager_2 = false
  if !scope.usager_2.inactive && (scope.usager_2.demandeur || scope.usager_2.present_au_moment_de_la_demande)
    has_usager_2 = true

  has_children = false
  for enfant in scope.enfants
    if !enfant.inactive && (enfant.demandeur || enfant.present_au_moment_de_la_demande)
      has_children = true

  if has_usager_1 && !has_usager_2 && !has_children
    recueil_da.profil_demande = 'ADULTE_ISOLE'
  if has_usager_2 && !has_usager_1 && !has_children
    recueil_da.profil_demande = 'ADULTE_ISOLE'

  if has_usager_1 && (has_usager_2 || has_children)
    recueil_da.profil_demande = 'FAMILLE'
  if has_usager_2 && (has_usager_1 || has_children)
    recueil_da.profil_demande = 'FAMILLE'


initWorkingScope = (scope, $modal) ->
  scope.working = false
  scope.saveDone = {}
  scope.rdvDone = {}
  scope.pdfDone = {}
  scope.workingModal = ->
    modalInstance = $modal.open(
      templateUrl: 'scripts/xin/modal/modal.html'
      controller: 'ModalInstanceAlertController'
      resolve:
        message: -> return "Un traitement est en cours."
    )



angular.module('app.views.premier_accueil', ['app.settings', 'ngRoute', 'ui.bootstrap',
                                             'xin.print', 'xin.recueil_da', 'xin.pdf',
                                             'xin.listResource', 'xin.tools',
                                             'ui.bootstrap.datetimepicker', 'angularMoment',
                                             'xin.session', 'xin.backend', 'xin.form',
                                             'xin.referential',
                                             'app.views.premier_accueil.modal', 'xin.uploadFile',
                                             'angular-bootstrap-select', 'sc-toggle-switch',
                                             'sc-button', 'xin.error'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/premier-accueil',
        templateUrl: 'scripts/views/premier_accueil/list_premier_accueils.html'
        controller: 'ListPremierAccueilController'
        breadcrumbs: 'Premier accueil'
        reloadOnSearch: false
        routeAccess: true,
      .when '/premier-accueil/nouveau-recueil',
        templateUrl: 'scripts/views/premier_accueil/show_premier_accueil.html'
        controller: 'CreatePremierAccueilController'
        breadcrumbs: [['Premier Accueil', '#/premier-accueil?statut=BROUILLON'], ['Nouveau recueil']]
      .when '/premier-accueil/:recueilDaId/rendez-vous',
        templateUrl: 'scripts/views/premier_accueil/show_rendez_vous.html'
        controller: 'ShowRendezVousController'
        referenceUrl: 'premier-accueil'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetRecueilDADefer = $q.defer()
          breadcrumbsGetRecueilDADefer.promise.then (recueilDa) ->
            breadcrumbsDefer.resolve([
              ['Premier accueil', '#/premier-accueil?statut=BROUILLON']
              [recueilDa.id, '#/premier-accueil/' + recueilDa.id]
              ['Rendez-vous', '#/premier-accueil/' + recueilDa.id + '/rendez-vous']
            ])
          return breadcrumbsDefer.promise
      .when '/premier-accueil/:recueilDaId',
        templateUrl: 'scripts/views/premier_accueil/show_premier_accueil.html'
        controller: 'ShowPremierAccueilController'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetRecueilDADefer = $q.defer()
          breadcrumbsGetRecueilDADefer.promise.then (recueilDa) ->
            breadcrumbsDefer.resolve([
              ['Premier accueil', '#/premier-accueil?statut=BROUILLON']
              [recueilDa.id, '#/premier-accueil/' + recueilDa.id]
            ])
          return breadcrumbsDefer.promise
      .when '/premier-accueil/:recueilDaId/prendre-rendez-vous',
        templateUrl: 'scripts/views/premier_accueil/book_rdv.html'
        controller: 'BookRdvController'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetRecueilDADefer = $q.defer()
          breadcrumbsGetRecueilDADefer.promise.then (recueilDa) ->
            breadcrumbsDefer.resolve([
              ['Premier accueil', '#/premier-accueil?statut=BROUILLON']
              [recueilDa.id, '#/premier-accueil/' + recueilDa.id]
              ["Prendre rendez-vous"]
            ])
          return breadcrumbsDefer.promise


  .controller 'ListPremierAccueilController', ($scope, $route, session, Backend, DelayedEvent, SETTINGS) ->
    $scope.lookup =
      per_page: "12"
      page: "1"
    $scope.site_affecte =
      sans_limite: false
      id: null

    session.getUserPromise().then(
      (user) ->
        if user.site_affecte?
          $scope.site_affecte.id = user.site_affecte.id
        else if user.role == "SUPPORT_NATIONAL"
          $scope.site_affecte.sans_limite = true
        else
          return

        $scope.current_statut = ''
        if $route.current.params.statut?
          $scope.current_statut = $route.current.params.statut

        $scope.brouillon_active = if $scope.current_statut == 'BROUILLON' then 'active' else ''
        $scope.pa_realise_active = if $scope.current_statut == 'PA_REALISE' then 'active' else ''
        $scope.demandeurs_identifies_active = if $scope.current_statut == 'DEMANDEURS_IDENTIFIES' then 'active' else ''
        $scope.gu_exploite_active = if $scope.current_statut == 'EXPLOITE' then 'active' else ''
        $scope.annule_active = if $scope.current_statut == 'ANNULE' then 'active' else ''
        $scope.all_active = if $scope.current_statut == '' then 'active' else ''

        Backend.all('recueils_da?fq=statut:BROUILLON').getList().then(
          (recueils_das) ->
            $scope.brouillon_nbr = parseInt(recueils_das._meta.total)
        )
        Backend.all('recueils_da?fq=statut:PA_REALISE').getList().then(
          (recueils_das) ->
            $scope.pa_realise_nbr = parseInt(recueils_das._meta.total)
        )
        Backend.all('recueils_da?fq=statut:DEMANDEURS_IDENTIFIES').getList().then(
          (recueils_das) ->
            $scope.demandeurs_identifies_nbr = parseInt(recueils_das._meta.total)
        )
        Backend.all('recueils_da?fq=statut:EXPLOITE').getList().then(
          (recueils_das) ->
            $scope.gu_exploite_nbr = parseInt(recueils_das._meta.total)
        )
        Backend.all('recueils_da?fq=statut:ANNULE').getList().then(
          (recueils_das) ->
            $scope.annule_nbr = parseInt(recueils_das._meta.total)
        )
        Backend.all('recueils_da').getList().then(
          (recueils_das) ->
            $scope.all_nbr = parseInt(recueils_das._meta.total)
        )

        if $route.current.params.statut?
          $scope.resourceBackend = Backend.all('recueils_da?fq=statut:' + $scope.current_statut)
        else
          $scope.resourceBackend = Backend.all('recueils_da')
    )

    $scope.links = null

    $scope.updateScope = (current_scope) ->
      current_scope.profil_demande = SETTINGS.PROFIL_DEMANDE
      current_scope.recueil_statut = SETTINGS.RECUEIL_STATUT
      for resource in current_scope.resources or []
        resource.demandeursCount = 0
        resource.demandeurs = ""
        if resource.usager_1.demandeur
          resource.demandeursCount++
          resource.demandeurs += current_scope.displayListText(resource.usager_1.prenoms)
          resource.demandeurs += resource.usager_1.nom + ", "
        if resource.usager_2? and resource.usager_2.demandeur
          resource.demandeursCount++
          resource.demandeurs += current_scope.displayListText(resource.usager_2.prenoms)
          resource.demandeurs += resource.usager_2.nom + ", "
        for enfant in resource.enfants or []
          if enfant.demandeur
            resource.demandeursCount++
            resource.demandeurs += current_scope.displayListText(enfant.prenoms)
            resource.demandeurs += enfant.nom + ", "
        resource.demandeurs = resource.demandeurs.substring(0, resource.demandeurs.length - 2)

    $scope.dtLoadingTemplate = ->
      return {
        html: '<img src="images/spinner.gif">'
      }



  .controller 'ShowRendezVousController', ($scope, $route, $routeParams, moment,
                                           $modal, Backend, session, SETTINGS,
                                           pdfFactory) ->
    initWorkingScope($scope, $modal)
    $scope.recueil_da = $routeParams.recueilDaId
    $scope.usagers = []
    $scope.site = null
    $scope.dateConvocation = null
    $scope.currentSite = null
    $scope.spa = null

    $scope.generatePdf = ->
      usagers = []
      angular.copy($scope.usagers, usagers)
      params =
        usagers: usagers
        site: $scope.site
        dateConvocation: $scope.dateConvocation
        currentSite: $scope.currentSite
        spa: $scope.spa
      pdf = pdfFactory('convocation', params)
      pdf.generate().then(
        () ->
          pdf.save("convocation.pdf")
          $scope.pdfDone.end?()
        (error) ->
          console.log(error)
          $scope.pdfDone.end?()
      )



  .controller 'ShowPremierAccueilController', ($scope, $route, $routeParams, moment
                                               $modal, Backend, session, SETTINGS,
                                               pdfFactory, is_minor,
                                               compute_errors) ->
    initWorkingScope($scope, $modal)
    gu_enregistrement_compute_scope($scope)
    $scope.profil_demande = SETTINGS.PROFIL_DEMANDE
    $scope.recueil_statut = SETTINGS.RECUEIL_STATUT

    $scope.recueil_da = {}
    $scope.statut = ''
    $scope.usager_1 = {}
    $scope.usager_2 =
      'langues_audition_OFPRA': []
      'demandeur': undefined
      'langues': []
      'inactive': false
      'vulnerabilite':
        'mobilite_reduite': false
    usagers = []
    pdf = null
    $scope.type_usager_label =
      usager1: "Usager 1"
      usager2: "Usager 2"
      enfant: "Enfant"

    # first declare usager_2 inactive to enable directive, then set it to
    # inactive to hide it.
    $scope.usager_2.inactive = true

    $scope.enfants = []

    $scope.$watch 'usager_1', ((value) ->
      compute_profil_demande($scope, $scope.recueil_da, is_minor)
    ), true
    $scope.$watch 'usager_2', ((value) ->
      compute_profil_demande($scope, $scope.recueil_da, is_minor)
    ), true
    $scope.$watch 'enfants', ((value) ->
      compute_profil_demande($scope, $scope.recueil_da, is_minor)
    ), true

    $scope.canCreerRecueil = false
    session.can('creer_recueil').then ()->
      $scope.canCreerRecueil = true

    session.getUserPromise().then (user) ->
      $scope.user = user.plain()

    $scope.initUsager = (usager) -> (
      usager.prenoms = usager.prenoms or []
      usager.nationalites = usager.nationalites or []
      usager.langues = usager.langues or []
      usager.langues_audition_OFPRA = usager.langues_audition_OFPRA or []
      return usager
    )


    Backend.one('recueils_da', $routeParams.recueilDaId).get().then(
      (recueilDa) ->
        $scope.statut = recueilDa.statut
        # breadcrums
        if breadcrumbsGetRecueilDADefer?
          breadcrumbsGetRecueilDADefer.resolve(recueilDa)
          breadcrumbsGetRecueilDADefer = undefined

        $scope.recueil_da = recueilDa

        if recueilDa.usager_1
          $scope.usager_1 = recueilDa.usager_1
        $scope.usager_1 = $scope.initUsager $scope.usager_1
        usagers.push({usager: $scope.usager_1, type_usager: "usager1"})

        if recueilDa.usager_2
          $scope.usager_2 = recueilDa.usager_2
          usagers.push({usager: $scope.usager_2, type_usager: "usager2"})
        $scope.usager_2 = $scope.initUsager $scope.usager_2

        if recueilDa.enfants?
          $scope.enfants = recueilDa.enfants
          for enfant in $scope.enfants
            enfant = $scope.initUsager enfant
            usagers.push({usager: enfant, type_usager: "enfant"})

        if recueilDa.statut != 'BROUILLON'
          params =
            recueil_da: $scope.recueil_da
            usagers: usagers
            type_usager_label: $scope.type_usager_label
          pdf = pdfFactory('recueil_pa', params)
    )

    $scope.addChild = ->
      new_enfant =
        'demandeur': undefined
        'vulnerabilite':
          'mobilite_reduite': false
      $scope.enfants.push(new_enfant)

    $scope.displayUsager2 = ->
      $scope.usager_2.inactive = false

    cleanForm = ->
      $scope.errors =
        _errors: []
      delete $scope.recueil_da._errors
      delete $scope.usager_1._errors
      delete $scope.usager_2._errors
      for pays_traverse in $scope.usager_1.pays_traverses or []
        delete pays_traverse._errors
      for pays_traverse in $scope.usager_2.pays_traverses or []
        delete pays_traverse._errors
      for enfant in $scope.enfants
        delete enfant._errors
        for pays_traverse in enfant.pays_traverses or []
          delete pays_traverse._errors


    $scope.cleanFiles = (files) ->
      cleaned_files = []
      if files?
        for file in files
          if file.id?
            cleaned_files.push(file.id)
      return cleaned_files


    $scope.constructRecueilDa = ->
      recueil_da = Backend.all('recueils_da').one($routeParams.recueilDaId)
      save_photo_data = []
      recueil_da.profil_demande = $scope.recueil_da.profil_demande

      if $scope.usager_1.pays_naissance == ''
        delete $scope.usager_1.pays_naissance
      if $scope.usager_1.demandeur
        if $scope.usager_1.type_demande != "REEXAMEN"
          delete $scope.usager_1.numero_reexamen
      else
        delete $scope.usager_1.type_demande
        delete $scope.usager_1.numero_reexamen
      $scope.recueil_da.usager_1 = $scope.usager_1
      recueil_da.usager_1 = $scope.usager_1
      if recueil_da.usager_1.photo?
        if recueil_da.usager_1.photo.id?
          save_photo_data.push({
            usager: recueil_da.usager_1
            id: recueil_da.usager_1.photo.id
            data: recueil_da.usager_1.photo._links.data
          })
          recueil_da.usager_1.photo = recueil_da.usager_1.photo.id
        else
          delete recueil_da.usager_1.photo
      recueil_da.usager_1.documents = $scope.cleanFiles(recueil_da.usager_1.documents)

      if $scope.usager_2.inactive != true
        if $scope.usager_2.inactive?
          delete $scope.usager_2.inactive
        if $scope.usager_2.pays_naissance == ''
          delete $scope.usager_2.pays_naissance
        if $scope.usager_2.photo?
          if $scope.usager_2.photo.id?
            save_photo_data.push({
              usager: $scope.usager_2
              id: $scope.usager_2.photo.id
              data: $scope.usager_2.photo._links.data
            })
            $scope.usager_2.photo = $scope.usager_2.photo.id
          else
            delete $scope.usager_2.photo
        if $scope.usager_2.demandeur
          if $scope.usager_2.type_demande != "REEXAMEN"
            delete $scope.usager_2.numero_reexamen
        else
          delete $scope.usager_2.type_demande
          delete $scope.usager_2.numero_reexamen

        recueil_da.usager_2 = $scope.usager_2
        recueil_da.usager_2.documents = $scope.cleanFiles(recueil_da.usager_2.documents)

      recueil_da.enfants = []
      for enfant in $scope.enfants
        if enfant.inactive?
          if enfant.inactive == true
            continue
          else
            delete enfant.inactive

        if enfant.pays_naissance == ''
          delete enfant.pays_naissance
        if enfant.demandeur
          if enfant.type_demande != "REEXAMEN"
            delete enfant.numero_reexamen
        else
          delete enfant.type_demande
          delete enfant.numero_reexamen
        if enfant.photo?
          if enfant.photo.id?
            save_photo_data.push({
              usager: enfant
              id: enfant.photo.id
              data: enfant.photo._links.data
            })
            enfant.photo = enfant.photo.id
          else
            delete enfant.photo

        enfant.documents = $scope.cleanFiles(enfant.documents)
        recueil_da.enfants.push(enfant)
      return {recueil_da: recueil_da, save_photo_data: save_photo_data}


    $scope.validateRecueil = ->
      $scope.saveRecueil("validate")

    $scope.saveRecueil = (action = "save") ->
      if $scope.working
        $scope.workingModal()
        return
      else
        modalInstance = $modal.open(
          templateUrl: 'scripts/views/premier_accueil/modal/confirm_save.html'
          controller: 'ModalInstanceConfirmSaveController'
          backdrop: false
          keyboard: false
          resolve:
            recueil_da: ->
              return $scope.recueil_da
            action: ->
              return action
        )
        modalInstance.result.then (answer) ->
          if answer
            $scope.working = true
            cleanForm()
            recueil_da_info = $scope.constructRecueilDa()
            recueil_da = recueil_da_info.recueil_da
            save_photo_data = recueil_da_info.save_photo_data
            recueil_da.put(null, {'if-match': $scope.recueil_da._version}).then(
              (new_recueil_da) ->
                if action == "save"
                  modalInstance = $modal.open(
                    templateUrl: 'scripts/views/premier_accueil/modal/recueil_saved.html'
                    controller: 'ModalInstanceRecueilSavedController'
                    backdrop: false
                    keyboard: false
                    resolve:
                      recueil_da: ->
                        return recueil_da
                  )
                  modalInstance.result.then((action) ->
                    if action == 'list'
                      window.location = '#/premier-accueil'
                    else
                      $route.reload()
                  )

                else if action == "validate"
                  $scope.recueil_da._version = new_recueil_da._version
                  Backend.all('recueils_da/' + new_recueil_da.id + '/pa_realise')
                    .post(null, null, null, {'if-match': $scope.recueil_da._version}).then(
                      (recueil_da) ->
                        window.location = "#/premier-accueil/#{$scope.recueil_da.id}/prendre-rendez-vous"

                      (error) -> manageSaveErrors(error, save_photo_data, action)
                  )

              (error) -> manageSaveErrors(error, save_photo_data, "save")
            )
          else
            # modal canceled
            if action == "save"
              $scope.saveDone.end?()
            else if action == "validate"
              $scope.rdvDone.end?()


    manageSaveErrors = (error, save_photo_data, action) ->
      for save_photo in save_photo_data
        save_photo.usager.photo =
          id: save_photo.id
          _links:
            data: save_photo.data
      manage_errors($scope, error, compute_errors, action)
      $scope.rdvDone.end?()


    $scope.printRecueil = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/premier_accueil/modal/select_lang.html'
        controller: 'ModalLanguagesController'
        backdrop: false
        keyboard: false
        resolve:
          languages: ->
            return pdf.getLanguages()
      )
      modalInstance.result.then (language) ->
        if language != false
          pdf.generate(language).then(
            () ->
              pdf.save("recueil-#{$scope.recueil_da.id}.pdf")
              $scope.pdfDone.end?()
            (error) ->
              console.log(error)
              $scope.pdfDone.end?()
          )
        else
          $scope.pdfDone.end?()



  .controller 'CreatePremierAccueilController', ($scope, $route, $routeParams, moment,
                                                 $modal, Backend, session,
                                                 SETTINGS, is_minor,
                                                 compute_errors) ->
    initWorkingScope($scope, $modal)
    gu_enregistrement_compute_scope($scope)
    $scope.profil_demande = SETTINGS.PROFIL_DEMANDE
    $scope.recueil_statut = SETTINGS.RECUEIL_STATUT

    $scope.site_affecte_id = null
    session.getUserPromise().then (user) ->
      if user.site_affecte?
        $scope.site_affecte_id = user.site_affecte.id

    $scope.editLocation = true
    $scope.recueil_da =
      profil_demande: ""
    $scope.statut = "BROUILLON"
    $scope.usager_1 =
      'vulnerabilite' :
        'mobilite_reduite': false
      'demandeur': undefined
    $scope.usager_2 =
      'vulnerabilite' :
        'mobilite_reduite': false
      'demandeur': undefined
      'langues_audition_OFPRA': []
      'langues': []
      'inactive': true
    $scope.enfants = []

    $scope.hideUsagers = false

    $scope.$watch 'usager_1', ((value) ->
      compute_profil_demande($scope, $scope.recueil_da, is_minor)
    ), true
    $scope.$watch 'usager_2', ((value) ->
      compute_profil_demande($scope, $scope.recueil_da, is_minor)
    ), true
    $scope.$watch 'enfants', ((value) ->
      compute_profil_demande($scope, $scope.recueil_da, is_minor)
    ), true

    $scope.canCreerRecueil = false
    session.can('creer_recueil').then ()->
      $scope.canCreerRecueil = true

    $scope.addChild = ->
      new_enfant =
        'vulnerabilite' :
          'mobilite_reduite': false
        'demandeur': undefined
      $scope.enfants.push(new_enfant)

    $scope.displayUsager2 = ->
      $scope.usager_2.inactive = false

    $scope.cleanFiles = (files) ->
      cleaned_files = []
      if files?
        for file in files
          if file.id?
            cleaned_files.push(file.id)
      return cleaned_files

    cleanForm = ->
      $scope.errors =
        _errors: []
      delete $scope.recueil_da._errors
      delete $scope.usager_1._errors
      delete $scope.usager_2._errors
      for pays_traverse in $scope.usager_1.pays_traverses or []
        delete pays_traverse._errors
      for pays_traverse in $scope.usager_2.pays_traverses or []
        delete pays_traverse._errors
      for enfant in $scope.enfants
        delete enfant._errors
        for pays_traverse in enfant.pays_traverses or []
          delete pays_traverse._errors

    $scope.saveRecueil = ->
      cleanForm()
      save_photo_data = []
      if $scope.usager_1.pays_naissance == ''
        delete $scope.usager_1.pays_naissance
      if $scope.usager_1.demandeur
        if $scope.usager_1.type_demande != "REEXAMEN"
          delete $scope.usager_1.numero_reexamen
      else
        delete $scope.usager_1.type_demande
        delete $scope.usager_1.numero_reexamen
      $scope.recueil_da.usager_1 = $scope.usager_1

      if $scope.recueil_da.usager_1.photo?
        if $scope.recueil_da.usager_1.photo.id?
          save_photo_data.push({
            usager: $scope.recueil_da.usager_1
            id: $scope.recueil_da.usager_1.photo.id
            data: $scope.recueil_da.usager_1.photo._links.data
          })
          $scope.recueil_da.usager_1.photo = $scope.recueil_da.usager_1.photo.id
        else
          delete $scope.recueil_da.usager_1.photo
      $scope.recueil_da.usager_1.documents = $scope.cleanFiles($scope.recueil_da.usager_1.documents)

      if $scope.usager_2.inactive != true
        if $scope.usager_2.inactive?
          delete $scope.usager_2.inactive
        if $scope.usager_2.pays_naissance == ''
          delete $scope.usager_2.pays_naissance
        if $scope.usager_2.demandeur
          if $scope.usager_2.type_demande != "REEXAMEN"
            delete $scope.usager_2.numero_reexamen
        else
          delete $scope.usager_2.type_demande
          delete $scope.usager_2.numero_reexamen
        $scope.recueil_da.usager_2 = $scope.usager_2

        if $scope.recueil_da.usager_2.photo?
          if $scope.recueil_da.usager_2.photo.id?
            save_photo_data.push({
              usager: $scope.recueil_da.usager_2
              id: $scope.recueil_da.usager_2.photo.id
              data: $scope.recueil_da.usager_2.photo._links.data
            })
            $scope.recueil_da.usager_2.photo = $scope.recueil_da.usager_2.photo.id
          else
            delete $scope.recueil_da.usager_2.photo
        $scope.recueil_da.usager_2.documents = $scope.cleanFiles($scope.recueil_da.usager_2.documents)

      $scope.recueil_da.enfants = []
      for enfant in $scope.enfants
        if enfant.inactive?
          if enfant.inactive == true
            continue
          else
            delete enfant.inactive

        if enfant.pays_naissance == ''
          delete enfant.pays_naissance
        if enfant.demandeur
          if enfant.type_demande != "REEXAMEN"
            delete enfant.numero_reexamen
        else
          delete enfant.type_demande
          delete enfant.numero_reexamen

        if enfant.photo?
          if enfant.photo.id?
            save_photo_data.push({
              usager: enfant
              id: enfant.photo.id
              data: enfant.photo._links.data
            })
            enfant.photo = enfant.photo.id
          else
            delete enfant.photo
        enfant.documents = $scope.cleanFiles(enfant.documents)

        $scope.recueil_da.enfants.push(enfant)

      modalInstance = $modal.open(
        templateUrl: 'scripts/views/premier_accueil/modal/confirm_save.html'
        controller: 'ModalInstanceConfirmSaveController'
        backdrop: false
        keyboard: false
        resolve:
          recueil_da: ->
            return $scope.recueil_da
          action: ->
            return "save"
      )
      modalInstance.result.then(
        (answer) ->
          if answer
            Backend.all('recueils_da').post($scope.recueil_da).then(
              (recueil_da) ->
                modalInstance = $modal.open(
                  templateUrl: 'scripts/views/premier_accueil/modal/recueil_saved.html'
                  controller: 'ModalInstanceRecueilSavedController'
                  backdrop: false
                  keyboard: false
                  resolve:
                    recueil_da: ->
                      return recueil_da
                )
                modalInstance.result.then (action) ->
                  if action == 'list'
                    window.location = '#/premier-accueil'
                  else
                    window.location = '#/premier-accueil/' + recueil_da.id

              (error) ->
                for save_photo in save_photo_data
                  save_photo.usager.photo =
                    id: save_photo.id
                    _links:
                      data: save_photo.data
                manage_errors($scope, error, compute_errors)
            )
          else
            for save_photo in save_photo_data
              save_photo.usager.photo =
                id: save_photo.id
                _links:
                  data: save_photo.data
            $scope.saveDone.end?()
      )



  .controller 'BookRdvController', ($scope, $route, $routeParams, $modal,
                                    session, Backend, SETTINGS,
                                    get_nb_demandeurs) ->
    $scope.recueil_da = {}
    nb_demandeurs = 0
    $scope.profil_demande = SETTINGS.PROFIL_DEMANDE
    $scope.csv_spinner = true
    $scope.active = null
    $scope.saveDone = {}
    $scope.error = undefined
    # DisplayByList
    # $scope.creneaux = {}
    # DisplayByGU
    $scope.creneaux_gu = {}
    $scope.dates = []
    $scope.slots = []

    $scope.creneaux = []
    $scope.sites = {}

    Backend.one('recueils_da', $routeParams.recueilDaId).get().then(
      (recueilDa) ->
        # breadcrums
        if breadcrumbsGetRecueilDADefer?
          breadcrumbsGetRecueilDADefer.resolve(recueilDa)
          breadcrumbsGetRecueilDADefer = undefined

        $scope.recueil_da = recueilDa.plain()
        nb_demandeurs = get_nb_demandeurs(recueilDa)
        getCreneaux('recueils_da/' + $scope.recueil_da.id + '/rendez_vous')
    )

    getCreneaux = (link) ->
      Backend.one(link).get().then(
        (data) ->
          for gu, index in data._sites
            $scope.sites[gu.id] = {libelle: gu.libelle, priorite: index}

          for creneaux_by_gu in data._items
            for creneaux_by_slot in creneaux_by_gu
              creneaux = creneaux_by_slot[0]
              creneaux.all = []
              begin = moment(creneaux.slot.split(" ")[0]).format("HH:mm")
              end = moment(creneaux.slot.split(" ")[2]).format("HH:mm")
              creneaux.slot = "#{begin} - #{end}"
              for creneau in creneaux_by_slot
                creneaux.all.push(creneau.id)
              $scope.creneaux.push(creneaux)

          $scope.creneaux.sort((a, b) ->
            # order by date
            if a.date != b.date
              date_a = moment(a.date, "DD/MM/YYYY")
              date_b = moment(b.date, "DD/MM/YYYY")
              diff = date_a.isAfter(date_b)
              return 1 if diff
              return -1
            # order by GU
            if a.gu != b.gu
              return $scope.sites[a.gu].priorite - $scope.sites[b.gu].priorite
            # order by time
            return a.slot.localeCompare(b.slot)
          )

          # if famille, regroup entries
          creneaux_count = $scope.creneaux.length
          if nb_demandeurs > 1 and creneaux_count > 1
            creneaux_famille = []
            for i in [0..creneaux_count-2]
              current_creneau = $scope.creneaux[i]
              current_time_start = current_creneau.slot.split(" ")[0]
              current_time_end = current_creneau.slot.split(" ")[2]
              for j in [i+1..creneaux_count-1]
                next_creneau = $scope.creneaux[j]
                next_time_start = next_creneau.slot.split(" ")[0]
                next_time_end = next_creneau.slot.split(" ")[2]
                if current_creneau.date == next_creneau.date and
                   current_creneau.gu == next_creneau.gu and
                   current_time_end == next_time_start
                  creneau = {}
                  angular.copy(current_creneau, creneau)
                  creneau.slot = "#{current_time_start} - #{next_time_end}"
                  creneau.all = [creneau.all, next_creneau.all]
                  creneaux_famille.push(creneau)
            $scope.creneaux = creneaux_famille

          $scope.csv_spinner = false
      )

    $scope.book = (creneau) ->
      $scope.active = creneau


    $scope.save = ->
      $scope.error = null
      if not $scope.active?
        $scope.error = "Aucun créneau n'est sélectionné."
        $scope.saveDone.end?()
        return

      payload =
        creneaux: []
      if nb_demandeurs > 1
        payload.creneaux = $scope.active.all
      else
        payload.creneaux = [$scope.active.all]

      # Post RDV
      Backend.all('recueils_da/' + $scope.recueil_da.id + '/pa_realise')
        .customPUT(payload, null, null, {'if-match': $scope.recueil_da._version}).then(
          (recueil_da) ->
            modalInstance = $modal.open(
              templateUrl: 'scripts/views/premier_accueil/modal/recueil_validated.html'
              controller: 'ModalInstanceRecueilValidatedController'
              backdrop: false
              keyboard: false
              resolve:
                recueil_da: ->
                  return recueil_da
            )
            modalInstance.result.then((action) ->
              if action == 'list'
                window.location = '#/premier-accueil'
              else if action == 'show'
                window.location = '#/premier-accueil/' + recueil_da.id
              else if action == 'rdv'
                window.location = '#/premier-accueil/' + recueil_da.id + '/rendez-vous'
            )

          (error) ->
            $scope.errors =
              _errors: []
            $scope.errors._errors.push("Le recueil n'a pas pu être enregistré.")

            if error.status == 400
              for key, value of error.data
                if key == '_errors'
                  for error in value
                    if "L'utilisateur doit avoir un StructureAccueil comme site_affecte pour pouvoir créer un receuil_da" in value
                      $scope.errors._errors.push("L'utilisateur doit être rattaché à une structure d'accueil pour pouvoir créer un recueil de demande d'asile")
                    else
                      $scope.errors._errors.push(error)
                else if key == 'usager_1'
                  for msg_key, msg_value of compute_errors(value)
                    $scope.errors._errors.push("usager_1." + msg_key + ": " + msg_value)
                else if key == 'usager_2'
                  if value == "Un usager secondaire est requis en cas de situation familiale MARIE, CONCUBIN ou PACSE"
                    $scope.errors._errors.push(value)
                  else
                    for msg_key, msg_value of compute_errors(value)
                      $scope.errors._errors.push("usager_2." + msg_key + ": " + msg_value)
                else if key == 'enfants'
                  for child_key, child_value of value
                    for msg_key, msg_value of compute_errors(child_value)
                      $scope.errors._errors.push("enfant[" + child_key + "]." + msg_key + ": " + msg_value)
                else if key == 'profil_demande'
                  $scope.errors._errors.push("Ajoutez au moins un usager demandeur.")
                else
                  $scope.errors[key] = value

            if error.status == 500
              $scope.errors._errors.push("Une erreur interne est survenue. Merci de contacter votre administrateur")
            $scope.saveDone.end?()
        )



  .directive 'usagerDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/premier_accueil/directive/usager.html'
    controller: 'UsagerController'
    scope:
      usager: '=?'
      typeUsager: '=?'
      deleteButton: '=?'
      editLocation: '=?'
      uDisabled: '=?'
      profilDemande: '=?'
      adresseReference: '=?'
      paysTraversesReference1: '=?'
      paysTraversesReference2: '=?'
      isCollapsed: '=?'
    link: (scope, elem, attrs) ->
      return



  .controller 'ConvocationController', ($scope, $route, $routeParams, moment,
                                        $modal, Backend, session, SETTINGS) ->
    $scope.pays_naissance = ''
    $scope.nationalites = ''

    if $scope.usager.pays_naissance? and $scope.usager.pays_naissance.code
      Backend.one('referentiels/pays/'+$scope.usager.pays_naissance.code).get().then(
        (pays) ->
          $scope.pays_naissance = pays.libelle
      )
    if $scope.usager.nationalites?
      nationalites = []
      for nationalite in $scope.usager.nationalites
        Backend.one('referentiels/nationalites/'+nationalite.code).get().then(
          (ref_nationalite) ->
            nationalites.push(ref_nationalite.libelle)
        )
      $scope.nationalites = nationalites



gu_enregistrement_compute_scope = (scope) ->
  scope.type_usager_1 = "usager1"
  scope.type_usager_2 = "usager2"
  scope.type_enfant = "enfant"
