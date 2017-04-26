'use strict'

breadcrumbsGetDADefer = undefined

initWorkingScope = (scope, $modal) ->
  scope.working = false
  scope.saveDone = {}
  scope.requalifDone = {}
  scope.editionAttestationDone = {}
  scope.workingModal = ->
    modalInstance = $modal.open(
      templateUrl: 'scripts/xin/modal/modal.html'
      controller: 'ModalInstanceAlertController'
      resolve:
        message: -> return "Un traitement est en cours."
    )


compute_errors = (error) ->
  _errors = {}
  if typeof(error) == 'object'
    for key, value of error
      if value instanceof Array
        value = value[0]
      if value == "Not a valid choice."
        value = "Choix invalide."
      _errors[key] = value
  return _errors



angular.module('app.views.da', ['app.settings', 'ngRoute', 'ui.bootstrap', 'xin.print',
                                'sc-toggle-switch',
                                'xin.listResource', 'xin.tools', 'ui.bootstrap.datetimepicker',
                                'xin.recueil_da',
                                'xin.session', 'xin.backend', 'xin.form', 'xin.referential',
                                'app.views.demande_asile.modal',
                                'angularMoment', 'angular-bootstrap-select'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/demandes-asiles',
        templateUrl: 'scripts/views/demande_asile/list_demandes_asiles.html'
        controller: 'ListDAController'
        breadcrumbs: 'Demandes d\'asile'
        reloadOnSearch: false
        routeAccess: true,
      .when '/demandes-asiles/:demandeAsileId',
        templateUrl: 'scripts/views/demande_asile/show_demande_asile.html'
        controller: 'ShowDAController'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetDADefer = $q.defer()
          breadcrumbsGetDADefer.promise.then (demandeAsile) ->
            breadcrumbsDefer.resolve([
              ['Demandes d\'asile', '#/demandes-asiles']
              [demandeAsile.id, '#/demandes-asiles/' + demandeAsile.id]
            ])
          return breadcrumbsDefer.promise
      .when '/demandes-asiles/telemOfpra/:numeroInerec',
        templateUrl: 'scripts/views/demande_asile/telemOfpra.html'
        controller: 'telemOfpraController'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetDADefer = $q.defer()
          breadcrumbsGetDADefer.promise.then (identifiant_inerec) ->
            breadcrumbsDefer.resolve([
              ['Demandes d\'asiles', '#/demandes-asiles']
              ['telemOfpra', '#/demandes-asiles/telemOfpra/' + identifiant_inerec]
            ])
          return breadcrumbsDefer.promise



  .controller 'ListDAController', ($scope, $route, $routeParams, $modal,
                                   session, Backend, BackendWithoutInterceptor,
                                   DelayedEvent, SETTINGS,
                                   pdfFactory) ->
    $scope.lookup =
      per_page: "12"
      page: "1"
    today = moment().startOf('day')

    # Get the current status written on the URL
    $scope.current_statut = $routeParams.statut or ''
    $scope.PERMISSIONS = SETTINGS.PERMISSIONS
    EXTRACT_STATUTS = [
      'DECISION_DEFINITIVE', 'DECISION_DEFINITIVE_ACCORD', 'DECISION_DEFINITIVE_REFUS',
      'FIN_PROCEDURE', 'FIN_PROCEDURE_ACCORD', 'FIN_PROCEDURE_REFUS'
    ]

    aCloturer = []
    $scope.others =
      TYPE_DEMANDE: SETTINGS.TYPE_DEMANDE
      extractAllowed: $scope.current_statut in EXTRACT_STATUTS
      cloturerAllowed: false
      selected: []
      requesting: []
      worked: []
      failed: []
      submitted: false
    pdfScope = null
    $scope.pdfDone = {}

    # Highlights the type of "demande d'asile" on the sidebar
    $scope.intro_ofpra_active = if $scope.current_statut == 'EN_ATTENTE_INTRODUCTION_OFPRA' then 'active' else ''
    $scope.intro_ofpra_reprise_active = if $scope.current_statut == 'EN_ATTENTE_INTRODUCTION_OFPRA_REPRISE' then 'active' else ''
    $scope.proc_dublin_active = if $scope.current_statut == 'EN_COURS_PROCEDURE_DUBLIN' then 'active' else ''
    $scope.proc_dublin_reprise_active = if $scope.current_statut == 'EN_COURS_PROCEDURE_DUBLIN_REPRISE' then 'active' else ''
    $scope.instruction_ofpra_active = if $scope.current_statut == 'EN_COURS_INSTRUCTION_OFPRA' then 'active' else ''
    $scope.instruction_ofpra_reprise_active = if $scope.current_statut == 'EN_COURS_INSTRUCTION_OFPRA_REPRISE' then 'active' else ''
    $scope.instruction_ofpra_requalif_active = if $scope.current_statut == 'EN_COURS_INSTRUCTION_OFPRA_REQUALIFICATION' then 'active' else ''
    $scope.instruction_ofpra_requalif_reprise_active = if $scope.current_statut == 'EN_COURS_INSTRUCTION_OFPRA_REQUALIFICATION_REPRISE' then 'active' else ''
    $scope.decision_def_active = if $scope.current_statut == 'DECISION_DEFINITIVE' then 'active' else ''
    $scope.decision_def_reprise_active = if $scope.current_statut == 'DECISION_DEFINITIVE_REPRISE' then 'active' else ''
    $scope.decision_def_accord_active = if $scope.current_statut == 'DECISION_DEFINITIVE_ACCORD' then 'active' else ''
    $scope.decision_def_accord_reprise_active = if $scope.current_statut == 'DECISION_DEFINITIVE_ACCORD_REPRISE' then 'active' else ''
    $scope.decision_def_refus_active = if $scope.current_statut == 'DECISION_DEFINITIVE_REFUS' then 'active' else ''
    $scope.decision_def_refus_reprise_active = if $scope.current_statut == 'DECISION_DEFINITIVE_REFUS_REPRISE' then 'active' else ''
    $scope.fin_proc_dublin_active = if $scope.current_statut == 'FIN_PROCEDURE_DUBLIN' then 'active' else ''
    $scope.fin_proc_dublin_reprise_active = if $scope.current_statut == 'FIN_PROCEDURE_DUBLIN_REPRISE' then 'active' else ''
    $scope.fin_proc_active = if $scope.current_statut == 'FIN_PROCEDURE' then 'active' else ''
    $scope.fin_proc_reprise_active = if $scope.current_statut == 'FIN_PROCEDURE_REPRISE' then 'active' else ''
    $scope.fin_proc_accord_active = if $scope.current_statut == 'FIN_PROCEDURE_ACCORD' then 'active' else ''
    $scope.fin_proc_accord_reprise_active = if $scope.current_statut == 'FIN_PROCEDURE_ACCORD_REPRISE' then 'active' else ''
    $scope.fin_proc_refus_active = if $scope.current_statut == 'FIN_PROCEDURE_REFUS' then 'active' else ''
    $scope.fin_proc_refus_reprise_active = if $scope.current_statut == 'FIN_PROCEDURE_REFUS_REPRISE' then 'active' else ''
    $scope.all_active = if $scope.current_statut == '' then 'active' else ''
    $scope.all_reprise_active = if $scope.current_statut == 'REPRISE' then 'active' else ''

    $scope.toggle =
      show: true
      overall: $routeParams.overall?
      left_label: "Globale"
      right_label: "Locale"

    $scope.$watch 'toggle.overall', (value, old_value) ->
      if old_value? and value != old_value
        window.location = "#/demandes-asiles?#{if value then 'overall&' else ''}statut=#{$scope.current_statut}"

    $scope.user = {}
    session.getUserPromise().then (user) ->
      $scope.user = user.plain()
      $scope.toggle.show = user.role not in ['SUPPORT_NATIONAL', 'GESTIONNAIRE_NATIONAL']

    route = if $scope.toggle.overall then 'demandes_asile?overall&' else 'demandes_asile?'
    # For each type, the number of "demande d'asile" will be draw on the sidebar
    Backend.all("#{route}fq=statut:EN_ATTENTE_INTRODUCTION_OFPRA").getList().then(
      (demandes_asiles) ->
        $scope.intro_ofpra_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:EN_COURS_PROCEDURE_DUBLIN").getList().then(
      (demandes_asiles) ->
        $scope.proc_dublin_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:EN_COURS_INSTRUCTION_OFPRA").getList().then(
      (demandes_asiles) ->
        $scope.instruction_ofpra_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:EN_COURS_INSTRUCTION_OFPRA AND da_procedure_acteur:OFPRA").getList().then(
      (demandes_asiles) ->
        $scope.instruction_ofpra_requalif_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:DECISION_DEFINITIVE").getList().then(
      (demandes_asiles) ->
        $scope.decision_def_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:DECISION_DEFINITIVE AND decision_definitive_resultat:ACCORD").getList().then(
      (demandes_asiles) ->
        $scope.decision_def_accord_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:DECISION_DEFINITIVE AND decision_definitive_resultat:REJET").getList().then(
      (demandes_asiles) ->
        $scope.decision_def_refus_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:FIN_PROCEDURE_DUBLIN").getList().then(
      (demandes_asiles) ->
        $scope.fin_proc_dublin_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:FIN_PROCEDURE").getList().then(
      (demandes_asiles) ->
        $scope.fin_proc_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:FIN_PROCEDURE AND decision_definitive_resultat:ACCORD").getList().then(
      (demandes_asiles) ->
        $scope.fin_proc_accord_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:FIN_PROCEDURE AND decision_definitive_resultat:REJET").getList().then(
      (demandes_asiles) ->
        $scope.fin_proc_refus_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=-statut:PRETE_EDITION_ATTESTATION").getList().then(
      (demandes_asiles) ->
        $scope.all_nbr = parseInt(demandes_asiles._meta.total)
    )

    # Dossiers repris-stock DNA
    fq_repise = "{!join from=doc_id to=prefecture_rattachee_r}libelle_s:loader-Prefecture"
    Backend.all("#{route}fq=statut:EN_ATTENTE_INTRODUCTION_OFPRA AND #{fq_repise}").getList().then(
      (demandes_asiles) ->
        $scope.intro_ofpra_reprise_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:EN_COURS_PROCEDURE_DUBLIN AND #{fq_repise}").getList().then(
      (demandes_asiles) ->
        $scope.proc_dublin_reprise_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:EN_COURS_INSTRUCTION_OFPRA AND #{fq_repise}").getList().then(
      (demandes_asiles) ->
        $scope.instruction_ofpra_reprise_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:EN_COURS_INSTRUCTION_OFPRA AND da_procedure_acteur:OFPRA AND #{fq_repise}").getList().then(
      (demandes_asiles) ->
        $scope.instruction_ofpra_requalif_reprise_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:DECISION_DEFINITIVE AND #{fq_repise}").getList().then(
      (demandes_asiles) ->
        $scope.decision_def_reprise_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:DECISION_DEFINITIVE AND decision_definitive_resultat:ACCORD AND #{fq_repise}").getList().then(
      (demandes_asiles) ->
        $scope.decision_def_accord_reprise_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:DECISION_DEFINITIVE AND decision_definitive_resultat:REJET AND #{fq_repise}").getList().then(
      (demandes_asiles) ->
        $scope.decision_def_refus_reprise_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:FIN_PROCEDURE_DUBLIN AND #{fq_repise}").getList().then(
      (demandes_asiles) ->
        $scope.fin_proc_dublin_reprise_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:FIN_PROCEDURE AND #{fq_repise}").getList().then(
      (demandes_asiles) ->
        $scope.fin_proc_reprise_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:FIN_PROCEDURE AND decision_definitive_resultat:ACCORD AND #{fq_repise}").getList().then(
      (demandes_asiles) ->
        $scope.fin_proc_accord_reprise_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=statut:FIN_PROCEDURE AND decision_definitive_resultat:REJET AND #{fq_repise}").getList().then(
      (demandes_asiles) ->
        $scope.fin_proc_refus_reprise_nbr = parseInt(demandes_asiles._meta.total)
    )
    Backend.all("#{route}fq=-statut:PRETE_EDITION_ATTESTATION AND #{fq_repise}").getList().then(
      (demandes_asiles) ->
        $scope.all_reprise_nbr = parseInt(demandes_asiles._meta.total)
    )

    if $scope.current_statut != ""
      fq = "statut:" + $scope.current_statut
      if $scope.current_statut == "EN_COURS_INSTRUCTION_OFPRA_REQUALIFICATION"
        fq = "statut:EN_COURS_INSTRUCTION_OFPRA AND da_procedure_acteur:OFPRA"
      else if $scope.current_statut == "DECISION_DEFINITIVE_ACCORD"
        fq = "statut:DECISION_DEFINITIVE AND decision_definitive_resultat:ACCORD"
      else if $scope.current_statut == "DECISION_DEFINITIVE_REFUS"
        fq = "statut:DECISION_DEFINITIVE AND decision_definitive_resultat:REJET"
      else if $scope.current_statut == "FIN_PROCEDURE_ACCORD"
        fq = "statut:FIN_PROCEDURE AND decision_definitive_resultat:ACCORD"
      else if $scope.current_statut == "FIN_PROCEDURE_REFUS"
        fq = "statut:FIN_PROCEDURE AND decision_definitive_resultat:REJET"

      # repris-stock DNA
      if $scope.current_statut == "EN_ATTENTE_INTRODUCTION_OFPRA_REPRISE"
        fq = "statut:EN_ATTENTE_INTRODUCTION_OFPRA AND #{fq_repise}"
      else if $scope.current_statut == "EN_COURS_PROCEDURE_DUBLIN_REPRISE"
        fq = "statut:EN_COURS_PROCEDURE_DUBLIN AND #{fq_repise}"
      else if $scope.current_statut == "EN_COURS_INSTRUCTION_OFPRA_REPRISE"
        fq = "statut:EN_COURS_INSTRUCTION_OFPRA AND #{fq_repise}"
      else if $scope.current_statut == "EN_COURS_INSTRUCTION_OFPRA_REQUALIFICATION_REPRISE"
        fq = "statut:EN_COURS_INSTRUCTION_OFPRA AND da_procedure_acteur:OFPRA AND #{fq_repise}"
      else if $scope.current_statut == "DECISION_DEFINITIVE_REPRISE"
        fq = "statut:DECISION_DEFINITIVE AND #{fq_repise}"
      else if $scope.current_statut == "DECISION_DEFINITIVE_ACCORD_REPRISE"
        fq = "statut:DECISION_DEFINITIVE AND decision_definitive_resultat:ACCORD AND #{fq_repise}"
      else if $scope.current_statut == "DECISION_DEFINITIVE_REFUS_REPRISE"
        fq = "statut:DECISION_DEFINITIVE AND decision_definitive_resultat:REJET AND #{fq_repise}"
      else if $scope.current_statut == "FIN_PROCEDURE_DUBLIN_REPRISE"
        fq = "statut:FIN_PROCEDURE_DUBLIN AND #{fq_repise}"
      else if $scope.current_statut == "FIN_PROCEDURE_REPRISE"
        fq = "statut:FIN_PROCEDURE AND #{fq_repise}"
      else if $scope.current_statut == "FIN_PROCEDURE_ACCORD_REPRISE"
        fq = "statut:FIN_PROCEDURE AND decision_definitive_resultat:ACCORD AND #{fq_repise}"
      else if $scope.current_statut == "FIN_PROCEDURE_REFUS_REPRISE"
        fq = "statut:FIN_PROCEDURE AND decision_definitive_resultat:REJET AND #{fq_repise}"
      else if $scope.current_statut == "REPRISE"
        fq = "-statut:PRETE_EDITION_ATTESTATION AND #{fq_repise}"

      $scope.resourceBackend = Backend.all("#{route}fq=#{fq}")
    else
      $scope.resourceBackend = Backend.all("#{route}fq=-statut:PRETE_EDITION_ATTESTATION")

    if not $scope.toggle.overall and $scope.current_statut in ["DECISION_DEFINITIVE", "DECISION_DEFINITIVE_ACCORD", "DECISION_DEFINITIVE_REFUS", "EN_COURS_PROCEDURE_DUBLIN"]
      $scope.others.cloturerAllowed = true

    $scope.updateResourcesList = (current_scope) ->
      for resource in current_scope.resources or []
        updateUsager(resource)
      # alertes expirations droits
      updateDroitsExpirations(current_scope.resources)
      checkConditionsExceptionelles(current_scope.resources)
      initPdf(current_scope)

    updateUsager = (resource) ->
      if resource.usager
        usager_route = "usagers/#{resource.usager.id}#{if $scope.toggle.overall then '?overall' else ''}"
        BackendWithoutInterceptor.one(usager_route).get().then(
          (usager) ->
            resource.usager = usager.plain()
            if pdfScope.start
              checkUsagerPdf(usager.id)
          (error) -> console.log(error)
        )

    updateDroitsExpirations = (resources) ->
      for resource in resources or []
        resource.droit_spinner = true
        resource.fin_validite = false
      url_overall = if $scope.toggle.overall then 'overall&' else ''
      updateDroitsExpirationsResource(resources, 0, url_overall)

    updateDroitsExpirationsResource = (resources, index, url_overall) ->
      resource = resources[index]
      if not resource?
        return
      url_usager = "fq=usager:#{resource.usager.id}&"
      checkEnRenouvellement(resources, index, url_overall, url_usager)

    checkEnRenouvellement = (resources, index, url_overall, url_usager) ->
      url_droit = "fq=sous_type_document:EN_RENOUVELLEMENT&"
      Backend.all("/droits?#{url_overall}#{url_usager}#{url_droit}per_page=1").getList().then (droits) ->
        if droits.plain().length == 0
          checkPremierRenouvellement(resources, index, url_overall, url_usager)
        else
          resources[index]["droit_spinner"] = false
          updateDroitsExpirationsResource(resources, ++index, url_overall)

    checkPremierRenouvellement = (resources, index, url_overall, url_usager) ->
      url_droit = "fq=sous_type_document:PREMIER_RENOUVELLEMENT&"
      Backend.all("/droits?#{url_overall}#{url_usager}#{url_droit}per_page=1&sort=_created desc").getList().then (droits) ->
        if droits.plain().length == 0
          checkPremiereDelivrance(resources, index, url_overall, url_usager)
        else
          resources[index]["droit_spinner"] = false
          droit = droits[0]
          date_fin_validite = moment(droit.date_fin_validite)
          if date_fin_validite.isBefore(today)
            resources[index]["fin_validite"] = true
          updateDroitsExpirationsResource(resources, ++index, url_overall)

    checkPremiereDelivrance = (resources, index, url_overall, url_usager) ->
      url_droit = "fq=sous_type_document:PREMIERE_DELIVRANCE&"
      Backend.all("/droits?#{url_overall}#{url_usager}#{url_droit}per_page=1&sort=_created desc").getList().then (droits) ->
        resources[index]["droit_spinner"] = false
        if droits.plain().length > 0
          droit = droits[0]
          date_fin_validite = moment(droit.date_fin_validite)
          if date_fin_validite.isBefore(today)
            resources[index]["fin_validite"] = true
        updateDroitsExpirationsResource(resources, ++index, url_overall)


    checkConditionsExceptionelles = (resources) ->
      for resource, index in resources or [] when resource.conditions_exceptionnelles_accueil
        if resource.statut in ["EN_COURS_INSTRUCTION_OFPRA"]
          if moment().isAfter(moment(resource.date_introduction_ofpra).subtract(1, 'days').add(4, 'months'))
            resources[index]["absence_decision"] = true


    ## Start PDF ##

    initPdf = (current_scope) ->
      pdfScope =
        start: false
        pays: false
        prev: false
        next: false
        scope: current_scope
        waitingUsagers: []
        params:
          resourcesList: current_scope.resources
          pays: {}
          user: ""
          status: $scope.current_statut
          site: ""
      session.getUserPromise().then (user) ->
        pdfScope.params.user = user.email
        if user.site_affecte?
          Backend.one(user.site_affecte._links.self).get().then (site) ->
            pdfScope.params.site = site.libelle


    checkUsagerPdf = (id) ->
      index = pdfScope.waitingUsagers.indexOf(parseInt(id))
      if index != -1
        pdfScope.waitingUsagers.splice(index, 1)
      endPdf()

    continuePdf = ->
      if pdfScope.prev and pdfScope.next
        endPdf()
      else
        continuePdfPrev(pdfScope.scope, false)
        continuePdfNext(pdfScope.scope, false)

    continuePdfPrev = (scope, concat = false) ->
      if concat
        pdfScope.params.resourcesList = scope.resources.concat(pdfScope.params.resourcesList)
      if scope.links.previous?
        previousBackend(scope.links.previous)
      else
        pdfScope.prev = true
        endPdf()

    continuePdfNext = (scope, concat = false) ->
      if concat
        pdfScope.params.resourcesList = pdfScope.params.resourcesList.concat(scope.resources)
      if scope.links.next?
        nextBackend(scope.links.next)
      else
        pdfScope.next = true
        endPdf()

    previousBackend = (link) ->
      Backend.all(link).getList().then (resources) ->
        for resource in resources or []
          pdfScope.waitingUsagers.push(resource.usager.id)
          updateUsager(resource)
        continuePdfPrev({resources: resources, links: resources._links}, true)

    nextBackend = (link) ->
      Backend.all(link).getList().then (resources) ->
        for resource in resources or []
          pdfScope.waitingUsagers.push(resource.usager.id)
          updateUsager(resource)
        continuePdfNext({resources: resources, links: resources._links}, true)

    endPdf = ->
      if pdfScope.prev and pdfScope.next and
         pdfScope.waitingUsagers.length == 0 and pdfScope.pays
        pdf = pdfFactory('decision_definitive', pdfScope.params)
        pdf.generate().then(
          () ->
            pdf.save("decision_definitive.pdf")
            $scope.pdfDone.end()
          (error) ->
            console.log(error)
            $scope.pdfDone.end()
        )

    $scope.pdf = ->
      pdfScope.start = true
      updatePays("referentiels/pays")
      continuePdf()

    updatePays = (url) ->
      Backend.all(url).getList().then (referentials) ->
        for referential in referentials.plain() or []
          pdfScope.params.pays[referential.code] = referential.libelle
        if referentials._links.next?
          updatePays(referentials._links.next)
        else
          pdfScope.pays = true
          endPdf()

    ## End PDF ##


    $scope.cloturer = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return "Êtes-vous sûr de vouloir procéder à la clôture des demandes d'asile sélectionnées ?"
          sub_message: ->
            return ""
      )
      modalInstance.result.then(
        (result) ->
          if result?
            $scope.others.submitted = true
            aCloturer = []
            for value, id in $scope.others.selected or []
              if value
                aCloturer.push(id)
                $scope.others.requesting[id] = true
            continueCloture()
      )

    reload = ->
      delayedFilter = new DelayedEvent(1500)
      delayedFilter.triggerEvent ->
        $route.reload()

    continueCloture = ->
      id = aCloturer.shift()
      if not id
        return
      Backend.all("demandes_asile/#{id}/fin_procedure").post({}).then(
        (result) ->
          $scope.others.requesting[id] = false
          $scope.others.worked[id] = true
          if aCloturer.length > 0
            continueCloture()
          else
            reload()
        (error) ->
          $scope.others.requesting[id] = false
          $scope.others.failed[id] = true
          if aCloturer.length > 0
            continueCloture()
          else
            reload()
      )



  .controller 'ShowDAController', ($scope, $route, $routeParams, moment, pdfFactory,
                                   $modal, Backend, BackendWithoutInterceptor,
                                   session, SETTINGS, is_minor) ->
    initWorkingScope($scope, $modal)
    $scope.printDADone = {}
    $scope.organisme_qualificateur = SETTINGS.ORGANISME_QUALIFICATEUR
    $scope.da_nature = SETTINGS.DECISION_DEFINITIVE_NATURE
    $scope.da_resultat = SETTINGS.DECISION_DEFINITIVE_RESULTAT
    $scope.selectOrigineNom = SETTINGS.ORIGINE_NOM
    $scope.conditionEntreeFrance = SETTINGS.CONDITION_ENTREE_EN_FRANCE
    $scope.qualification = SETTINGS.QUALIFICATION
    $scope.motifsConditionsExceptionnellesAccueil = SETTINGS.CONDITIONS_EXCEPTIONNELLES_ACCUEIL
    $scope.type_demande = SETTINGS.TYPE_DEMANDE
    $scope.PERMISSIONS = SETTINGS.PERMISSIONS
    $scope.MOTIF_DELIVRANCE_ATTESTATION = SETTINGS.MOTIF_DELIVRANCE_ATTESTATION
    $scope.SOUS_TYPE_DOCUMENT = SETTINGS.SOUS_TYPE_DOCUMENT
    $scope.lieux_delivrances = {}
    last_decision_attestation = null

    $scope.localisations =
      'dna': { 'title': 'Mise à jour de DN@', 'data': undefined }
      'agdref': { 'title': 'Mise à jour d\'AGDREF', 'data': undefined }
      'ofpra': { 'title': 'Mise à jour d\'OFPRA', 'data': undefined }

    $scope.portail = undefined
    $scope.droits = []
    $scope.nb_en_renouvellement = 0
    $scope.show_decisions_attestation = false
    $scope.uDisabled = true

    user_site_affecte = null
    user_autorite_rattachement = null
    session.getUserPromise().then (user) ->
      $scope.user = user.plain()
      $scope.canModifierDA = not $routeParams.overall? and 'modifier_da' in $scope.PERMISSIONS[user.role]
      if user.site_affecte?
        Backend.one("/sites/#{user.site_affecte.id}").get().then(
          (site_affecte) ->
            user_site_affecte = site_affecte.plain()
            if site_affecte.autorite_rattachement?
              Backend.one("/sites/#{site_affecte.autorite_rattachement.id}").get().then(
                (autorite) ->
                  user_autorite_rattachement = autorite.plain()
              )
        )

    initUsager = (usager) ->
      usager.prenoms = usager.prenoms or []
      usager.nationalites = usager.nationalites or []
      usager.langues = usager.langues or []
      usager.langues_audition_OFPRA = usager.langues_audition_OFPRA or []
      return usager

    $scope.$watch 'demande_asile.procedure.type', (value, old_value) ->
      if value? and SETTINGS.QUALIFICATION[value]?
        $scope.selectMotifQualification = SETTINGS.QUALIFICATION[value]
      else
        $scope.selectMotifQualification = []

    _getLocalisation = (url) ->
      Backend.all(url).getList().then(
        (localisations) ->
          for localisation in localisations
            if (localisation.organisme_origine == "DNA")
              if $scope.localisations.dna.data == undefined or
                 $scope.localisations.dna.data.date_maj < localisation.date_maj
                $scope.localisations.dna.data = angular.copy(localisation)
            else if (localisation.organisme_origine == "AGDREF")
              if $scope.localisations.agdref.data == undefined or
                 $scope.localisations.agdref.data.date_maj < localisation.date_maj
                $scope.localisations.agdref.data = angular.copy(localisation)
            else if (localisation.organisme_origine == "INEREC")
              if $scope.localisations.ofpra.data == undefined or
                 $scope.localisations.ofpra.data.date_maj < localisation.date_maj
                $scope.localisations.ofpra.data = angular.copy(localisation)
            else if (localisation.organisme_origine == "PORTAIL")
              if $scope.portail == undefined or !$scope.portail.date_maj or
                 $scope.portail.date_maj < localisation.date_maj
                $scope.portail = angular.copy(localisation)
          if localisations._meta.next
            _getLocalisation(localisations._meta.next)
      )

    # Use to know if we are on overall or local view
    $scope.overallView = $routeParams.overall?
    url_overall = if $scope.overallView then '?overall' else ''
    route = "demandes_asile/#{$routeParams.demandeAsileId}#{url_overall}"
    Backend.one(route).get().then(
      (demandeAsile) ->
        # breadcrums
        if breadcrumbsGetDADefer?
          breadcrumbsGetDADefer.resolve(demandeAsile)
          breadcrumbsGetDADefer = undefined

        $scope.demande_asile = demandeAsile.plain()
        if demandeAsile.decisions_attestation? and demandeAsile.decisions_attestation.length
          last_decision_attestation = demandeAsile.decisions_attestation[demandeAsile.decisions_attestation.length-1]
        else
          last_decision_attestation =
            decision: true
        $scope.cloturerAllowed = false
        if demandeAsile.statut? and demandeAsile.statut in ["DECISION_DEFINITIVE", "DECISION_DEFINITIVE_ACCORD", "DECISION_DEFINITIVE_REFUS", "EN_COURS_PROCEDURE_DUBLIN"]
          $scope.cloturerAllowed = true
        $scope.display_requalifications = false
        if demandeAsile.procedure.acteur == "OFPRA"
          $scope.display_requalifications = true
        if not $scope.display_requalifications and demandeAsile.procedure? and
           demandeAsile.procedure.requalifications?
          for requalification in demandeAsile.procedure.requalifications
            if requalification.ancien_acteur == "OFPRA"
              $scope.display_requalifications = true
              break
        if $scope.demande_asile.dublin? and $scope.demande_asile.dublin.EM?
          $scope.demande_asile.dublin.EM = $scope.demande_asile.dublin.EM.id
        for decision in demandeAsile.decisions_attestation or [] when decision.delivrance == false
          $scope.show_decisions_attestation = true
        Backend.one("usagers/#{demandeAsile.usager.id}#{url_overall}").get().then(
          (usager) ->
            $scope.nom = usager.nom
            $scope.nom_usage = usager.nom_usage
            $scope.isMinor = is_minor(usager.date_naissance)
            $scope.usager = initUsager(usager.plain())

            url_separator = if $scope.overallView then '&' else '?'
            _getLocalisation("usagers/#{$scope.usager.id}/localisations#{url_overall}#{url_separator}per_page=10")
        )
    )

    Backend.all("/droits?fq=demande_origine_r:#{$routeParams.demandeAsileId}&sort=doc_created_dt asc").getList().then(
      (droits) ->
        $scope.droits = droits.plain()
        for droit in droits
          if droit.sous_type_document == "EN_RENOUVELLEMENT"
            $scope.nb_en_renouvellement++
          if droit.supports
            for support in droit.supports
              Backend.one(support.lieu_delivrance._links.self).get().then(
                (site) ->
                  $scope.lieux_delivrances[site.id] = site.libelle
              )
    )

    redirect = (da_attestation) ->
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
      modalInstance.result.then (result) ->
        if result == true
          $route.reload()

    generatePdfAndRedirect = (droit) ->
      $scope.nom = $scope.usager.nom
      $scope.nom_usage = $scope.usager.nom_usage
      $scope.attestation_label = SETTINGS.ATTESTATION_LABEL
      $scope.isMinor = is_minor($scope.usager.date_naissance)
      support = droit.supports[droit.supports.length-1]
      params =
        usager: $scope.usager
        isMinor: $scope.isMinor
        demande_asile: $scope.demande_asile
        lieu_delivrance: user_site_affecte.libelle
        date_delivrance: support.date_delivrance
        droit: droit
        attestation_label: $scope.attestation_label
        is_duplicata: $scope.is_duplicata
      if user_autorite_rattachement?
        params.lieu_delivrance = user_autorite_rattachement.libelle
      pdf = pdfFactory('attestation', params)
      pdf.generate().then(
        () ->
          pdf.save("attestation-#{$scope.demande_asile.id}.pdf")
          redirect($scope.demande_asile)
        (error) ->
          console.log(error)
          redirect($scope.demande_asile)
      )

    $scope.editAttestation = ->
      if $scope.working
        $scope.workingModal()
        $scope.editionAttestationDone.end()
        return
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/demande_asile/modal/edition_attestation.html'
        controller: 'ModalEditionAttestationController'
        backdrop: false
        keyboard: false
        resolve:
          da: -> return $scope.demande_asile
          droits: -> return $scope.droits
      )
      modalInstance.result.then (droit) ->
        if droit
          $scope.is_duplicata = droit.duplicata or false
          generatePdfAndRedirect(droit.droit)
        else
          $scope.editionAttestationDone.end()

    $scope.requalification = ->
      if $scope.working
        $scope.requalifDone.end()
        $scope.workingModal()
        return
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/demande_asile/modal/requalification.html'
        controller: 'ModalInstanceRequalificationController'
        backdrop: false
        keyboard: false
        resolve:
          da: ->
            return $scope.demande_asile
      )
      modalInstance.result.then (answer) ->
        if not answer
          $scope.requalifDone.end?()
        else
          $route.reload()


    $scope.cloturer = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return "Êtes-vous sûr de vouloir procéder à la clôture de la demande d'asile ?"
          sub_message: ->
            return ""
      )
      modalInstance.result.then(
        (result) ->
          if result?
            Backend.all("demandes_asile/#{$scope.demande_asile.id}/fin_procedure").post({}).then(
              (result) ->
                $route.reload()
              (error) ->
                $scope._errors = "Impossible de clôturer la demande d'asile."
            )
      )

    $scope.telemOfpra = ->
      session.getUserPromise().then(
        (user) ->
          payload = {
            "date_demande" : moment()
            "agent" : user.id
            "demande_asile" : $scope.demande_asile.id
            "identifiant_inerec" : $scope.demande_asile.identifiant_inerec
          }
          Backend.all('telemOfpra').post(payload).then(
            (telemOfpra) ->
              window.location = '#/demandes-asiles/telemOfpra/' + $scope.demande_asile.identifiant_inerec
            (error) ->
              $scope._errors = "Impossible d'accéder au lien TelemOfpra."
          )
      )

    $scope.save = ->
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
            return "Vous allez modifier la demande d'asile."
          sub_message: ->
            return ""
      )
      modalInstance.result.then (result) ->
        if not result
          $scope.working = false
          $scope.saveDone.end?()
          return
        $scope.working = true
        $scope._errors = null
        patch =
          date_entree_en_france: $scope.demande_asile.date_entree_en_france
          date_entree_en_france_approximative: $scope.demande_asile.date_entree_en_france_approximative
          date_depart: $scope.demande_asile.date_depart
          date_depart_approximative: $scope.demande_asile.date_depart_approximative
          condition_entree_france: $scope.demande_asile.condition_entree_france
          visa: $scope.demande_asile.visa
          conditions_exceptionnelles_accueil: $scope.demande_asile.conditions_exceptionnelles_accueil
          motif_conditions_exceptionnelles_accueil: null
        if $scope.demande_asile.motif_conditions_exceptionnelles_accueil? and
           $scope.demande_asile.motif_conditions_exceptionnelles_accueil != ""
          patch.motif_conditions_exceptionnelles_accueil = $scope.demande_asile.motif_conditions_exceptionnelles_accueil
        Backend.one(route).patch(patch, null, {'if-match': $scope.demande_asile._version}).then(
          () ->
            modalInstance = $modal.open(
              templateUrl: 'scripts/xin/modal/modal.html'
              controller: 'ModalInstanceForceConfirmController'
              backdrop: false
              keyboard: false
              resolve:
                message: ->
                  return "La demande d'asile a été enregistrée."
                sub_message: ->
                  return ""
            )
            modalInstance.result.then(
              (result) ->
                $route.reload()
            )
          (error) ->
            if error.status == 400
              $scope._errors = "Impossible de sauvegarder la demande d'asile."
              if "motif_conditions_exceptionnelles_accueil" in Object.keys(error.data) and
                 error.data.motif_conditions_exceptionnelles_accueil[0] == "Not a valid choice."
                error.data.motif_conditions_exceptionnelles_accueil[0] = "Champ requis"
              $scope.demande_asile._errors = compute_errors(error.data)
            if error.status == 412
              $scope._errors = "La sauvegarde des modifications est impossible, cette demande d'asile a été modifiée entre-temps par un autre utilisateur."
            else
              $scope._errors = "Impossible de sauvegarder la demande d'asile."
            $scope.working = false
            $scope.saveDone.end?()
        )

    $scope.printDA = () ->
      params =
        demande_asile: $scope.demande_asile
        usager: $scope.usager
        droits: $scope.droits
        lieux_delivrances: $scope.lieux_delivrances
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


  .controller 'telemOfpraController', ($scope, $sce, $route, $routeParams, $window, session, SETTINGS) ->
    $scope.identifiant_inerec = $routeParams.numeroInerec
    $scope.iframeURL = $sce.trustAsResourceUrl("#{SETTINGS.TELEM_OFPRA_URL}?user=#{SETTINGS.TELEM_OFPRA_USER}&numDossier=" + $scope.identifiant_inerec)

    # breadcrums
    if breadcrumbsGetDADefer?
      breadcrumbsGetDADefer.resolve($scope.identifiant_inerec)
      breadcrumbsGetDADefer = undefined

    $scope.updateHeight = ->
      # navbar: 50px / footer: 60 px / clearfix: .actionbar.height() + 12
      $scope.heightIframe = window.innerHeight - 50 - angular.element(".actionbar")[0].clientHeight - 20 - 60

    # clearfix: 80 px
    $scope.heightIframe = window.innerHeight - 190

    angular.element($window).bind 'resize', ->
      $scope.updateHeight()
      $scope.$apply()


  .directive 'usagerDaDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/demande_asile/directive/usager.html'
    controller: 'UsagerController'
    scope:
      usager: '=?'
      typeUsager: '=?'
      deleteButton: '=?'
      editLocation: '=?'
      uDisabled: '=?'
      profilDemande: '=?'
    link: (scope, elem, attrs) ->
      scope.uDisabled = true
      return
