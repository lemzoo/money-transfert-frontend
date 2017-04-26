'use strict'

breadcrumbsGetAttestationDefer = undefined

initWorkingScope = (scope, $modal) ->
  scope.working = false
  scope.attribAttestationDone = {}
  scope.workingModal = ->
    modalInstance = $modal.open(
      templateUrl: 'scripts/xin/modal/modal.html'
      controller: 'ModalInstanceAlertController'
      resolve:
        message: -> return "Un traitement est en cours."
    )


angular.module('app.views.attestation', ['app.settings', 'ngRoute', 'ui.bootstrap', 'xin.print', 'sc-toggle-switch',
                                        'xin.listResource', 'xin.tools', 'ui.bootstrap.datetimepicker',
                                        'xin.session', 'xin.backend', 'xin.form', 'xin.referential', 'app.views.attestation.modal',
                                        'angularMoment', 'angular-bootstrap-select'])

  .config ($routeProvider) ->
    $routeProvider
      .when '/attestations',
        templateUrl: 'scripts/views/attestation/list_attestations.html'
        controller: 'ListAttestationsController'
        breadcrumbs: 'Edition d\'attestation'
        reloadOnSearch: false
        routeAccess: true,
      .when '/attestations/:demandeAsileId',
        templateUrl: 'scripts/views/demande_asile/show_demande_asile.html'
        controller: 'ShowAttestationController'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetAttestationDefer = $q.defer()
          breadcrumbsGetAttestationDefer.promise.then (demandeAsile) ->
            breadcrumbsDefer.resolve([
              ['Edition d\'attestation', '#/attestations']
              [demandeAsile.id, '#/attestations/' + demandeAsile.id]
            ])
          return breadcrumbsDefer.promise


  .controller 'ListAttestationsController', ($scope, $route, session, Backend, DelayedEvent, SETTINGS) ->
    $scope.lookup =
      per_page: "12"
      page: "1"
    $scope.others =
      TYPE_DEMANDE: SETTINGS.TYPE_DEMANDE

    session.getUserPromise().then(
      (user) ->
        $scope.site_affecte_id = '""'
        if user.site_affecte?
          $scope.site_affecte_id = user.site_affecte.id

        $scope.current_statut = ''
        if $route.current.params.statut?
          $scope.current_statut = $route.current.params.statut

        # Filter field is trigger after 500ms of inactivity
        delayedFilter = new DelayedEvent(500)
        $scope.filterField = ''
        $scope.$watch 'filterField', (filterValue) ->
          delayedFilter.triggerEvent ->
            if filterValue? and filterValue != ''
              $scope.lookup.q = filterValue
            else if $scope.lookup.q?
              delete $scope.lookup.q
        $scope.resourceBackend = Backend.all('demandes_asile?fq=statut:PRETE_EDITION_ATTESTATION')
    )

    $scope.complement =
      usagers: []

    $scope.updateResourcesList = (scope) ->
      for resource in scope.resources
        if resource.usager?
          Backend.one(resource.usager._links.self).get().then(
            (usager) ->
              $scope.complement.usagers[usager.id] = usager
          )


  .controller 'ShowAttestationController', ($scope, $route, $routeParams, moment,
                                            $modal, Backend, session, SETTINGS, pdfFactory,
                                            is_minor) ->

    initWorkingScope($scope, $modal)
    $scope.uDisabled = true
    $scope.printDADone = {}
    $scope.demande_asile = {}
    $scope.usager = {}
    $scope.organisme_qualificateur = SETTINGS.ORGANISME_QUALIFICATEUR
    $scope.da_nature = SETTINGS.DECISION_DEFINITIVE_NATURE
    $scope.da_resultat = SETTINGS.DECISION_DEFINITIVE_RESULTAT
    $scope.selectOrigineNom = SETTINGS.ORIGINE_NOM
    $scope.conditionEntreeFrance = SETTINGS.CONDITION_ENTREE_EN_FRANCE
    $scope.motifsConditionsExceptionnellesAccueil = SETTINGS.CONDITIONS_EXCEPTIONNELLES_ACCUEIL
    $scope.type_demande = SETTINGS.TYPE_DEMANDE
    lieu_delivrance = null
    lieu_delivrance_id = null
    droits = []

    session.getUserPromise().then (user) ->
      $scope.user = user.plain()
      $scope.canModifierDA = 'modifier_da' in SETTINGS.PERMISSIONS[user.role]
      if user.site_affecte?
        Backend.one('/sites/' + user.site_affecte.id).get().then (site_affecte) ->
          if site_affecte.autorite_rattachement?
            Backend.one("/sites/#{site_affecte.autorite_rattachement.id}").get().then (autorite) ->
              lieu_delivrance = autorite.libelle
              lieu_delivrance_id = autorite.id
          else
            lieu_delivrance = site_affecte.libelle
            lieu_delivrance_id = site_affecte.id

    $scope.$watch 'demande_asile.procedure.type', (value, old_value) ->
      if value? and SETTINGS.QUALIFICATION[value]?
        $scope.selectMotifQualification = SETTINGS.QUALIFICATION[value]
      else
        $scope.selectMotifQualification = []

    Backend.one('demandes_asile', $routeParams.demandeAsileId).get().then(
      (demandeAsile) ->
        # breadcrums
        if breadcrumbsGetAttestationDefer?
          breadcrumbsGetAttestationDefer.resolve(demandeAsile)
          breadcrumbsGetAttestationDefer = undefined

        if demandeAsile.statut != 'PRETE_EDITION_ATTESTATION'
          window.location = "#/demandes-asiles/" + demandeAsile.id

        $scope.demande_asile = demandeAsile.plain()
        Backend.one(demandeAsile.usager._links.self).get().then(
          (usager) ->
            $scope.usager = initUsager(usager.plain())
        )
    )

    droit_url = "/droits?fq=demande_origine_r:#{$routeParams.demandeAsileId}"
    Backend.all(droit_url).getList().then (droits_req) ->
      droits = droits_req.plain()

    initUsager = (usager) ->
      usager.prenoms = usager.prenoms or []
      usager.nationalites = usager.nationalites or []
      usager.langues = usager.langues or []
      usager.langues_audition_OFPRA = usager.langues_audition_OFPRA or []
      $scope.portail = angular.copy(usager.localisation)
      return usager

    $scope.redirect = (da_attestation) ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceForceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return "L'attestation a été générée en PDF."
          sub_message: ->
            return "Ouvrez le fichier téléchargé pour imprimer l'attestation."
      )
      modalInstance.result.then(
        (result) ->
          if result == true
            window.location = "#/demandes-asiles/" + da_attestation.id
      )

    $scope.generatePdfAndRedirect = ->
      $scope.nom = $scope.usager.nom
      $scope.nom_usage = $scope.usager.nom_usage

      $scope.attestation_label = SETTINGS.ATTESTATION_LABEL
      $scope.isMinor = is_minor($scope.usager.date_naissance)

      params =
        usager: $scope.usager
        isMinor: $scope.isMinor
        demande_asile: $scope.demande_asile
        lieu_delivrance: lieu_delivrance
        date_delivrance: $scope.date_delivrance
        droit: $scope.droit
        attestation_label: $scope.attestation_label
        is_duplicata: $scope.is_duplicata

      pdf = pdfFactory('attestation', params)
      pdf.generate().then(
        () ->
          pdf.save("attestation-#{$scope.demande_asile.id}.pdf")
          $scope.redirect($scope.demande_asile)
        (error) ->
          console.log(error)
          $scope.redirect($scope.demande_asile)
      )

    $scope.printAttestation = ->
      date_decision_sur_attestation = $scope.demande_asile.date_decision_sur_attestation
      if droits.length
        date_decision_sur_attestation = moment()
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/attestation/modal/confirm_attestation.html'
        controller: 'ModalInstanceConfirmAttestationController'
        backdrop: false
        keyboard: false
        resolve:
          procedure: ->
            return $scope.demande_asile.procedure.type
          date_decision_sur_attestation: ->
            return date_decision_sur_attestation
      )
      modalInstance.result.then(
        (action) ->
          if action == false
            $scope.attribAttestationDone.end?()
            return
          # Create an attestation right
          right =
            "date_debut_validite" : action.date_debut_validite
            "date_fin_validite" : action.date_fin_validite
            "date_decision_sur_attestation" : action.date_decision_sur_attestation

          url = "demandes_asile/#{$scope.demande_asile.id}/attestations"
          Backend.all(url).post(right, null, null, {'if-match' : $scope.demande_asile._version}).then(
            (da_attestation) ->
              # Add a support
              $scope.date_delivrance = moment()
              support_payload =
                date_delivrance: $scope.date_delivrance
                lieu_delivrance: lieu_delivrance_id
              Backend.all(da_attestation.droit._links.support_create).post(support_payload).then(
                (supportDroit) ->
                  $scope.support = supportDroit.supports[supportDroit.supports.length - 1]
              )
              $scope.droit = da_attestation.droit
              $scope.generatePdfAndRedirect()
            (error) ->
              $scope.errors = []
              if error.status == 412
                $scope.errors.push("La sauvegarde des modifications est impossible, cette demande d'asile a été modifié entre-temps par un autre utilisateur.")
              $scope.attribAttestationDone.end?()
          )
      )

    $scope.printDA = () ->
      params =
        demande_asile: $scope.demande_asile
        usager: $scope.usager
        droits: $scope.droits
        requalifications: $scope.display_requalifications
        localisations: $scope.localisations
        portail: $scope.portail
      pdf = pdfFactory('demande_asile', params)
      pdf.generate().then(
        () ->
          pdf.save("demande_asile-#{$scope.demande_asile.id}.pdf")
          $scope.printDADone.end()
        (error) ->
          console.log(error)
          $scope.printDADone.end()
      )
