'use strict'

breadcrumbsGetRecueilDADefer = undefined


updateUsagersVersion = ($scope, recueil_da) ->
  if recueil_da.usager_1? and recueil_da.usager_1.usager_existant?
    $scope.usager_1.usager_existant._version = recueil_da.usager_1.usager_existant._version
  if recueil_da.usager_2? and recueil_da.usager_2.usager_existant?
    $scope.usager_2.usager_existant._version = recueil_da.usager_2.usager_existant._version
  for enfant, index in recueil_da.enfants or [] when enfant.usager_existant?
    $scope.enfants[index].usager_existant._version = enfant.usager_existant._version


compute_profil_demande = (scope, recueil_da, is_minor) ->
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
  scope.validateDone = {}
  scope.eurodacDone = {}
  scope.pdfDone = {}
  scope.cancelRdv = {}
  scope.workingModal = ->
    modalInstance = $modal.open(
      templateUrl: 'scripts/xin/modal/modal.html'
      controller: 'ModalInstanceAlertController'
      resolve:
        message: -> return "Un traitement est en cours."
    )



angular.module('app.views.gu_enregistrement', ['app.settings', 'ngRoute', 'ui.bootstrap',
                                               'xin.print', 'ui.calendar',
                                               'xin.listResource', 'xin.tools',
                                               'ui.bootstrap.datetimepicker',
                                               'xin.modal',
                                               'xin.session', 'xin.backend', 'xin.form',
                                               'xin.referential',
                                               'xin.pdf', 'xin.uploadFile',
                                               'app.views.gu_enregistrement.modal',
                                               'app.views.premier_accueil.modal',
                                               'angularMoment', 'sc-toggle-switch',
                                               'angular-bootstrap-select', 'xin.error',
                                               "app.views.gu_enregistrement_service"])
  .config ($routeProvider) ->
    $routeProvider
      .when '/gu-enregistrement',
        templateUrl: 'scripts/views/gu_enregistrement/list_gu_enregistrements.html'
        controller: 'ListGUEnregistrementController'
        breadcrumbs: 'GU - Enregistrement'
        reloadOnSearch: false
        routeAccess: true,

      .when '/gu-enregistrement/nouveau-recueil',
        templateUrl: 'scripts/views/gu_enregistrement/show_gu_enregistrement.html'
        controller: 'NouveauGUEnregistrementController'
        breadcrumbs: [['Guichet Unique', '#/gu-enregistrement?statut=PA_REALISE'], ['Nouveau recueil']]

      .when '/gu-enregistrement/:recueilDaId',
        templateUrl: 'scripts/views/gu_enregistrement/show_gu_enregistrement.html'
        controller: 'ShowGUEnregistrementController'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetRecueilDADefer = $q.defer()
          breadcrumbsGetRecueilDADefer.promise.then (recueilDa) ->
            breadcrumbsDefer.resolve([
              ['Guichet Unique - Enregistrement', '#/gu-enregistrement?statut=PA_REALISE']
              [recueilDa.id, '#/gu-enregistrement/' + recueilDa.id]
            ])
          return breadcrumbsDefer.promise

      .when '/gu-enregistrement/:recueilDaId/convocation',
        templateUrl: 'scripts/views/gu_enregistrement/show_rendez_vous.html'
        controller: 'ShowRendezVousController'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetRecueilDADefer = $q.defer()
          breadcrumbsGetRecueilDADefer.promise.then (recueilDa) ->
            breadcrumbsDefer.resolve([
              ['GU - Enregistrement', '#/gu-enregistrement?statut=BROUILLON']
              [recueilDa.id, '#/gu-enregistrement/' + recueilDa.id]
              ['Rendez-vous', '#/gu-enregistrement/' + recueilDa.id + '/rendez-vous']
            ])
          return breadcrumbsDefer.promise

      .when '/gu-enregistrement/:recueilDaId/rendez-vous',
        templateUrl: 'scripts/views/gu_enregistrement/directive/gerer_rdv.html'
        controller: 'RendezVousHandlerController'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetRecueilDADefer = $q.defer()
          breadcrumbsGetRecueilDADefer.promise.then (recueilDa) ->
            breadcrumbsDefer.resolve([
              ['Premier accueil', '#/gu-enregistrement?statut=PA_REALISE']
              [recueilDa.id, '#/gu-enregistrement/' + recueilDa.id]
              ['Rendez-vous', '#/gu-enregistrement/' + recueilDa.id + '/rendez-vous']
            ])
          return breadcrumbsDefer.promise



  .controller 'ListGUEnregistrementController', ($scope, $route, $location,
                                                 $routeParams, $modal,
                                                 $q,
                                                 session, Backend,
                                                 BackendWithoutInterceptor,
                                                 DelayedEvent,
                                                 SETTINGS, moment, pdfFactory,
                                                 is_minor_14,
                                                 get_nb_usagers_mobilite_reduite) ->
    pdfParams =
      dateToDisplay: null
      resourcesList: []
    pdfScope =
      scope: null
      prev: false
      next: false
      isGenerating: false
    $scope.lookup =
      per_page: "12"
      page: "1"
    $scope.complement =
      f_injoignable: (service) ->
        modalInstance = $modal.open(
          controller: "ModalInstanceForceConfirmController"
          templateUrl: "scripts/xin/modal/modal.html"
          backdrop: false
          keyboard: false
          resolve:
            message: () ->
              return "La communication avec le service #{service} est actuellement indisponible. Merci de réessayer dans un moment en actualisant la page."
            sub_message: -> return ""
        )
        modalInstance.result.then () -> return


    $scope.dateToDisplay = moment()
    $scope.changeDisplay = ->
      $scope.displayPlanning = !$scope.displayPlanning

      if !$scope.displayPlanning
        $location.search("planning", null).replace()
        $scope.lookup.fq = $routeParams.fq
      else
        setFilterDateSolr()

    $scope.abort = $q.defer()
    cancelRequest = ->
      $scope.abort.resolve()
      $scope.abort = $q.defer()

    setFilterDateSolr = ->
      cancelRequest()
      $scope.planning = 'rendez_vous_gu_date:[' + angular.copy($scope.dateToDisplay).format('YYYY-MM-DD[T]00:00:00[Z]') + ' TO ' + angular.copy($scope.dateToDisplay).add(1, 'days').format('YYYY-MM-DD[T]00:00:00[Z]') + ']'

      if ($routeParams.fq? and $routeParams.fq != '')
        $scope.lookup.fq = $scope.planning + ' AND ' + $routeParams.fq
      else
        $scope.lookup.fq = $scope.planning

      $location.search("planning", angular.copy($scope.dateToDisplay).format('YYYY-MM-DD')).replace()

    $scope.nextDay = ->
      $scope.dateToDisplay.add(1, 'days')
      setFilterDateSolr()

    $scope.prevDay = ->
      $scope.dateToDisplay.subtract(1, 'days')
      setFilterDateSolr()

    watchPhotos = (current_scope, resource, index) ->
      host = SETTINGS.API_BASE_URL
      clas = ".photos-#{index}"
      current_scope.$watch(
        () -> return angular.element.find(clas).length
        (value) ->
          if not value? or value == 0
            return
          elmt = $(clas)
          elmt.empty()
          if resource.usager_1? and resource.usager_1.demandeur
            if resource.usager_1.photo?
              elmt.append("<img src=\"#{host+resource.usager_1.photo._links.data}\" class=\"pull-right\" height=\"80px\"></img>")
            else if resource.usager_1.photo_premier_accueil?
              elmt.append("<img src=\"#{host+resource.usager_1.photo_premier_accueil._links.data}\" class=\"pull-right\" height=\"80px\"></img>")
          if resource.usager_2? and resource.usager_2.demandeur
            if resource.usager_2.photo?
              elmt.append("<img src=\"#{host+resource.usager_2.photo._links.data}\" class=\"pull-right\" height=\"80px\"></img>")
            else if resource.usager_2.photo_premier_accueil?
              elmt.append("<img src=\"#{host+resource.usager_2.photo_premier_accueil._links.data}\" class=\"pull-right\" height=\"80px\"></img>")
          for enfant in resource.enfants or [] when enfant.demandeur
            if enfant.photo?
              elmt.append("<img src=\"#{host+enfant.photo._links.data}\" class=\"pull-right\" height=\"80px\"></img>")
            else if enfant.photo_premier_accueil?
              elmt.append("<img src=\"#{host+enfant.photo_premier_accueil._links.data}\" class=\"pull-right\" height=\"80px\"></img>")
      )


    getUsagerExistant = (current_scope, indexRecueil, type_usager, indexEnfant) ->
      usager = current_scope.resources[indexRecueil][type_usager]
      if type_usager == "enfants"
        usager = usager[indexEnfant]
      BackendWithoutInterceptor.one(usager.usager_existant._links.self).get().then(
        (usagerResource) ->
          for key, value of usagerResource.plain()
            usager[key] = value

          if type_usager == "usager_1"
            getNextUsagerExistant(current_scope, indexRecueil, "usager_2", indexEnfant)
          else if type_usager == "usager_2"
            getNextUsagerExistant(current_scope, indexRecueil, "enfants", 0)
          else
            getNextUsagerExistant(current_scope, indexRecueil, "enfants", ++indexEnfant)
        (error) ->
          if error.status != 403
            console.log(error)
          if type_usager == "usager_1"
            getNextUsagerExistant(current_scope, indexRecueil, "usager_2", indexEnfant)
          else if type_usager == "usager_2"
            getNextUsagerExistant(current_scope, indexRecueil, "enfants", 0)
          else
            getNextUsagerExistant(current_scope, indexRecueil, "enfants", ++indexEnfant)
      )


    getNextUsagerExistant = (current_scope, indexRecueil, type_usager, indexEnfant) ->
      resource = current_scope.resources[indexRecueil]
      # usagers existant
      if type_usager == "usager_1"
        usager = resource[type_usager]
        if usager? and usager.usager_existant?
          getUsagerExistant(current_scope, indexRecueil, type_usager, indexEnfant)
        else
          type_usager = "usager_2"
      if type_usager == "usager_2"
        usager = resource[type_usager]
        if usager? and usager.usager_existant?
          getUsagerExistant(current_scope, indexRecueil, type_usager, indexEnfant)
        else
          type_usager = "enfants"
      if type_usager == "enfants"
        usager = resource[type_usager]
        if usager?
          usager = usager[indexEnfant]
          if usager?
            if usager.usager_existant?
              getUsagerExistant(current_scope, indexRecueil, "enfants", indexEnfant)
            else
              getNextUsagerExistant(current_scope, indexRecueil, "enfants", ++indexEnfant)
          else
            processRecueil(current_scope, indexRecueil)
        else
          processRecueil(current_scope, indexRecueil)


    computeNextRecueil = (current_scope, indexRecueil) ->
      resource = current_scope.resources[indexRecueil]
      if resource?
        getNextUsagerExistant(current_scope, indexRecueil, "usager_1", 0)
        Backend.one("sites/#{resource.structure_accueil.id}").get().then(
          (site) ->
            resource.siteLibelle =  site.libelle
        )
        resource.nb_usagers_mobilite_reduite = get_nb_usagers_mobilite_reduite(resource)
      else if pdfScope.isGenerating
        scope =
          resources: current_scope.resources
          links: current_scope.resources._links
        continuePdfWay(scope, true)


    processRecueilForPdf = (current_scope, indexRecueil) ->
      resource = current_scope.resources[indexRecueil]
      # date convocation and minor +14
      resource.date_convocation = '?'
      if resource.rendez_vous_gu? and resource.rendez_vous_gu.date?
        resource.date_convocation = resource.rendez_vous_gu.date
      if resource.rendez_vous_gu? and resource.rendez_vous_gu.marge?
        moment_date = moment(resource.date_convocation)
        moment_date.subtract(resource.rendez_vous_gu.marge, 'minutes')
        resource.date_convocation = moment_date._d
      # enfants +14
      if resource.enfants
        resource.child_presents_count = 0
        for enfant in resource.enfants
          if enfant.demandeur or enfant.present_au_moment_de_la_demande
            resource.child_presents_count++
            if is_minor_14(enfant.date_naissance)
              resource.child_14 = true


    processRecueil = (current_scope, indexRecueil) ->
      if not pdfScope.isGenerating
        resource = current_scope.resources[indexRecueil]
        # demandeurs
        resource.demandeursCount = 0
        resource.demandeurs =
          names: ""
        watchPhotos(current_scope, resource, indexRecueil)
        if resource.usager_1.demandeur
          resource.demandeursCount++
          resource.demandeurs.names += current_scope.displayListText(resource.usager_1.prenoms)
          resource.demandeurs.names += resource.usager_1.nom + ", "
        if resource.usager_2? and resource.usager_2.demandeur
          resource.demandeursCount++
          resource.demandeurs.names += current_scope.displayListText(resource.usager_2.prenoms)
          resource.demandeurs.names += resource.usager_2.nom + ", "
        for enfant in resource.enfants or []
          if enfant.demandeur
            resource.demandeursCount++
            resource.demandeurs.names += current_scope.displayListText(enfant.prenoms)
            resource.demandeurs.names += enfant.nom + ", "
        resource.demandeurs.names = resource.demandeurs.names.substring(0, resource.demandeurs.names.length - 2)

      # rendez-vous and balises
      processRecueilForPdf(current_scope, indexRecueil)
      # next recueil
      computeNextRecueil(current_scope, ++indexRecueil)


    $scope.updateScope = (current_scope) ->
      current_scope.profil_demande = SETTINGS.PROFIL_DEMANDE
      current_scope.recueil_statut = SETTINGS.RECUEIL_STATUT
      computeNextRecueil(current_scope, 0)
      # pdf
      pdfParams.dateToDisplay = $scope.dateToDisplay
      initPdf(current_scope)

    allow_fne = (usager, statut) ->
      if statut == "PA_REALISE"
        return true
      else if statut == "DEMANDEURS_IDENTIFIES" and usager? and not usager.demandeur
        return true
      else
        return false

    set_fpr_fne = (resources) ->
      for resource in resources or []
        if resource.statut == "ANNULE"
          continue
        usager_1 = resource.usager_1
        if usager_1?
          resource.fpr_spinner = true
          if allow_fne(usager_1, resource.statut)
            resource.fne_spinner = true
            continue
        usager_2 = resource.usager_2
        if usager_2?
          resource.fpr_spinner = true
          if allow_fne(usager_2, resource.statut)
            resource.fne_spinner = true
            continue
        enfants = resource.enfants
        for enfant in enfants or []
          if enfant?
            resource.fpr_spinner = true
            if allow_fne(enfant, resource.statut)
              resource.fne_spinner = true
              break
      get_fpr_fne(resources, 0)

    get_fpr_fne = (resources, index) ->
      resource = resources[index]
      if not resource?
        return
      if resource.statut == "ANNULE"
        return get_fpr_fne(resources, ++index)
      usager_1 = resource.usager_1
      usager_2 = resource.usager_2
      enfants = resource.enfants
      if usager_1?
        get_fpr_usager(resources, index, "usager_1", usager_1)
      else if usager_2?
        get_fpr_usager(resources, index, "usager_2", usager_2)
      else
        for enfant, key in enfants or []
          if enfant?
            get_fpr_usager(resources, index, "enfant", enfant, key)
            break

    get_fpr_fne_next_usager = (resources, index, type_usager, usager, index_enfant = -1) ->
      resource = resources[index]
      has_next_usager = false
      if type_usager == "usager_1"
        if resource.usager_2?
          has_next_usager = true
          get_fpr_usager(resources, index, "usager_2", resource.usager_2)
        else
          for enfant, key in resource.enfants or []
            if enfant?
              has_next_usager = true
              get_fpr_usager(resources, index, "enfant", enfant, key)
              break
      else if type_usager == "usager_2"
        for enfant, key in resource.enfants or []
            if enfant?
              has_next_usager = true
              get_fpr_usager(resources, index, "enfant", enfant, key)
              break
      else if type_usager == "enfant"
        for enfant, key in resource.enfants or [] when key > index_enfant
            if enfant?
              has_next_usager = true
              get_fpr_usager(resources, index, "enfant", enfant, key)
              break
      if not has_next_usager
        resource.fne_spinner = false
        resource.fpr_spinner = false
        get_fpr_fne(resources, ++index)

    get_fpr_usager = (resources, index, type_usager, usager, index_enfant = -1) ->
      resource = resources[index]
      date_naissance = moment(usager.date_naissance).format('YYYYMMDD')
      nom = usager.nom
      prenom = ""
      for u_prenom in usager.prenoms
        if prenom != ""
          prenom += " "
        prenom += u_prenom

      prenom = prenom.substring(0, 25)
      Backend.one('recherche_fpr?nom=' + nom + '&prenom=' + prenom + '&date_naissance=' + date_naissance).get().then(
        (result) ->
          if result.resultat? and result.resultat.resultat
            resource.fpr_spinner = false
            resource.fpr = true
          if allow_fne(usager, resource.statut)
            get_fne_usager(resources, index, type_usager, usager, index_enfant)
          else
            get_fpr_fne_next_usager(resources, index, type_usager, usager, index_enfant)

        (error) ->
          resource.fpr_spinner = false
          resource.fpr = false
          resource.no_fpr = true
          if allow_fne(usager, resource.statut)
            get_fne_usager(resources, index, type_usager, usager, index_enfant)
          else
            get_fpr_fne_next_usager(resources, index, type_usager, usager, index_enfant)
      )

    get_fne_usager = (resources, index, type_usager, usager, index_enfant = -1) ->
      resource = resources[index]
      date_naissance = moment(usager.date_naissance).format('YYYY-MM-DD')
      nom_fne = usager.nom
      prenom_fne = ""
      for prenom in usager.prenoms
        prenom_fne += prenom
        prenom_fne += " "
      sexe = usager.sexe
      Backend.one('recherche_usagers_tiers?nom=' + nom_fne + '&date_naissance=' + date_naissance + '&prenom=' + prenom_fne + '&sexe=' + sexe).get().then(
        (items) ->
          pf_items = false
          fne_items = false
          if items['PLATEFORME']
            pf_items = items['PLATEFORME'].length > 0 ? true : false

          if items['FNE']
            if items['FNE']['errors'] and items['FNE']['errors'].length > 0
              resource.no_fne = false
              pf_items = false
            else
              if items['FNE'].usagers? and items['FNE'].usagers.length > 0
                other_than_me = false
                for fne_usager in items['FNE'].usagers
                  if fne_usager != usager.identifiant_agdref
                    other_than_me = true
                if other_than_me
                  fne_items = true

          if pf_items or fne_items
            resource.fne_spinner = false
            resource.fne = true
          get_fpr_fne_next_usager(resources, index, type_usager, usager, index_enfant)
        (error) ->
          resource.fne_spinner = false
          resource.fne = false
          resource.no_fne = true
          get_fpr_fne_next_usager(resources, index, type_usager, usager, index_enfant)
      )


    previousBackend = (link) ->
      Backend.all(link).getList().then (resources) ->
        computeNextRecueil({resources: resources}, 0)

    nextBackend = (link) ->
      Backend.all(link).getList().then (resources) ->
        computeNextRecueil({resources: resources}, 0)

    initPdf = (current_scope) ->
      pdfScope.prev = false
      pdfScope.next = false
      pdfScope.scope = current_scope
      pdfParams.resourcesList = current_scope.resources

    continuePdf = ->
      pdfScope.isGenerating = true
      if pdfScope.prev and pdfScope.next
        endPdf()
      else
        continuePdfWay(pdfScope.scope, false)

    continuePdfWay = (scope, concat = false) ->
      if concat
        if not pdfScope.prev
          pdfParams.resourcesList = scope.resources.concat(pdfParams.resourcesList)
        else
          pdfParams.resourcesList = pdfParams.resourcesList.concat(scope.resources)
      if not pdfScope.prev
        if scope.links.previous?
          previousBackend(scope.links.previous)
        else
          pdfScope.prev = true
          continuePdfWay(scope, false)
      else
        if scope.links.next?
          nextBackend(scope.links.next)
        else
          pdfScope.next = true
          endPdf()


    endPdf = ->
      pdfScope.isGenerating = false
      pdf = pdfFactory('planning_jour_gu', pdfParams)
      pdf.generate().then(
        () -> pdf.save("planning.pdf")
        (error) -> console.log(error)
      )

    if $route.current.params.statut == '(PA_REALISE OR DEMANDEURS_IDENTIFIES)'
      if ($routeParams.planning? and $routeParams.planning != '')
        if ($routeParams.planning == true)
          $scope.dateToDisplay = moment()
        else
          $scope.dateToDisplay = moment($routeParams.planning)

        $scope.displayPlanning = true
        setFilterDateSolr()
      else
        $scope.displayPlanning = false


    session.getUserPromise().then(
      (user) ->
        $scope.user = user.plain()
        $scope.site_affecte =
          id: null
          sans_limite: false
        if user.site_affecte?
          $scope.site_affecte.id = user.site_affecte.id
        else if user.role in ["SUPPORT_NATIONAL", "GESTIONNAIRE_NATIONAL"]
          $scope.site_affecte.sans_limite = true
        else
          return

        $scope.current_statut = ''
        if $route.current.params.statut?
          $scope.current_statut = $route.current.params.statut
        $scope.planning_active = if $scope.current_statut == '(PA_REALISE OR DEMANDEURS_IDENTIFIES)' then 'active' else ''
        $scope.pa_realise_active = if $scope.current_statut == 'PA_REALISE' then 'active' else ''
        $scope.pa_realise_reprise_active = if $scope.current_statut == 'PA_REALISE_REPRISE' then 'active' else ''
        $scope.demandeurs_identifies_active = if $scope.current_statut == 'DEMANDEURS_IDENTIFIES' then 'active' else ''
        $scope.demandeurs_identifies_reprise_active = if $scope.current_statut == 'DEMANDEURS_IDENTIFIES_REPRISE' then 'active' else ''
        $scope.gu_exploite_active = if $scope.current_statut == 'EXPLOITE' then 'active' else ''
        $scope.gu_exploite_reprise_active = if $scope.current_statut == 'EXPLOITE_REPRISE' then 'active' else ''
        $scope.annule_active = if $scope.current_statut == 'ANNULE' then 'active' else ''
        $scope.annule_reprise_active = if $scope.current_statut == 'ANNULE_REPRISE' then 'active' else ''
        $scope.all_active = if $scope.current_statut == '' then 'active' else ''
        $scope.all_reprise_active = if $scope.current_statut == 'REPRISE' then 'active' else ''
        Backend.all('recueils_da?per_page=0&fq=statut:PA_REALISE').getList().then(
          (recueils_das) ->
            $scope.pa_realise_nbr = parseInt(recueils_das._meta.total)
        )
        Backend.all('recueils_da?per_page=0&fq=statut:DEMANDEURS_IDENTIFIES').getList().then(
          (recueils_das) ->
            $scope.demandeurs_identifies_nbr = parseInt(recueils_das._meta.total)
        )
        Backend.all('recueils_da?per_page=0&fq=statut:EXPLOITE').getList().then(
          (recueils_das) ->
            $scope.gu_exploite_nbr = parseInt(recueils_das._meta.total)
        )
        Backend.all('recueils_da?per_page=0&fq=statut:ANNULE').getList().then(
          (recueils_das) ->
            $scope.annule_nbr = parseInt(recueils_das._meta.total)
        )
        Backend.all('recueils_da?per_page=0&fq=-statut:BROUILLON').getList().then(
          (recueils_das) ->
            $scope.all_nbr = parseInt(recueils_das._meta.total)
        )

        # Dossiers repris-stock DNA
        fq_repise = "{!join from=doc_id to=prefecture_rattachee_r}libelle_s:loader-Prefecture"
        Backend.all("recueils_da?per_page=0&fq=statut:PA_REALISE AND #{fq_repise}").getList().then(
          (recueils_das) ->
            $scope.pa_realise_reprise_nbr = parseInt(recueils_das._meta.total)
        )
        Backend.all("recueils_da?per_page=0&fq=statut:DEMANDEURS_IDENTIFIES AND #{fq_repise}").getList().then(
          (recueils_das) ->
            $scope.demandeurs_identifies_reprise_nbr = parseInt(recueils_das._meta.total)
        )
        Backend.all("recueils_da?per_page=0&fq=statut:EXPLOITE AND #{fq_repise}").getList().then(
          (recueils_das) ->
            $scope.gu_exploite_reprise_nbr = parseInt(recueils_das._meta.total)
        )
        Backend.all("recueils_da?per_page=0&fq=statut:ANNULE AND #{fq_repise}").getList().then(
          (recueils_das) ->
            $scope.annule_reprise_nbr = parseInt(recueils_das._meta.total)
        )
        Backend.all("recueils_da?per_page=0&fq=-statut:BROUILLON AND #{fq_repise}").getList().then(
          (recueils_das) ->
            $scope.all_reprise_nbr = parseInt(recueils_das._meta.total)
        )
        $scope.lookup.sort = 'rendez_vous_gu_date_dt asc'
        if $scope.current_statut != ""
          fq = "statut:" + $scope.current_statut
          if $scope.current_statut == "PA_REALISE_REPRISE"
            fq = "statut:PA_REALISE AND #{fq_repise}"
          else if $scope.current_statut == "DEMANDEURS_IDENTIFIES_REPRISE"
            fq = "statut:DEMANDEURS_IDENTIFIES AND #{fq_repise}"
          else if $scope.current_statut == "EXPLOITE_REPRISE"
            fq = "statut:EXPLOITE AND #{fq_repise}"
          else if $scope.current_statut == "ANNULE_REPRISE"
            fq = "statut:ANNULE AND #{fq_repise}"
          else if $scope.current_statut == "REPRISE"
            fq = "-statut:BROUILLON AND #{fq_repise}"
          $scope.resourceBackend = BackendWithoutInterceptor.all('recueils_da?fq=' + fq + '&sort=' + $scope.lookup.sort)
        else
          $scope.resourceBackend = BackendWithoutInterceptor.all('recueils_da?fq=-statut:BROUILLON&sort=' + $scope.lookup.sort)
    )

    $scope.pdf = ->
      continuePdf()



  .controller 'ShowGUEnregistrementController', ($scope, $route, $routeParams, moment,
                                                 $modal, Backend, BackendWithoutInterceptor,
                                                 session, SETTINGS, pdfFactory, is_minor,
                                                 compute_errors, init_usager_for_recueil,
                                                 clean_usager_to_save, bindUsagerExistant) ->
    initWorkingScope($scope, $modal)
    $scope.profil_demande = SETTINGS.PROFIL_DEMANDE
    $scope.recueil_statut = SETTINGS.RECUEIL_STATUT
    $scope.PERMISSIONS = SETTINGS.PERMISSIONS

    $scope.searchIdEnabled = false
    $scope.all_eurodac_attrib = false
    $scope.date_entree_en_france = ''
    $scope.date_depart = ''
    $scope.origin_date_entree_en_france = ''
    $scope.origin_date_depart = ''
    $scope.recueil_da = {}
    $scope.usager_1 =
      active: false
    $scope.usager_2 =
      active: false
    $scope.enfants = []
    usagers = []
    pdf = null
    type_usager_label =
      usager1: "Usager 1"
      usager2: "Usager 2"
      enfant: "Enfant"

    $scope.hideUsagers = false

    session.getUserPromise().then (user) ->
      $scope.user = user.plain()

    checkEurodac = ->
      if $scope.usager_1.demandeur and not $scope.usager_1.identifiant_eurodac?
        $scope.all_eurodac_attrib = false
        return
      if $scope.usager_2? and not $scope.usager_2.inactive and
         $scope.usager_2.demandeur and not $scope.usager_2.identifiant_eurodac?
        $scope.all_eurodac_attrib = false
        return
      if $scope.enfants?
        for enfant in $scope.enfants or []
          if not enfant.inactive and enfant.demandeur and not enfant.identifiant_eurodac?
            $scope.all_eurodac_attrib = false
            return
      $scope.all_eurodac_attrib = true


    checkUsagerExistant = (usager) ->
      if usager.usager_existant?
        BackendWithoutInterceptor.one("/usagers/#{usager.usager_existant.id}").get().then(
          (existing_usager) ->
            bindUsagerExistant(existing_usager, usager)
        )

    Backend.one('recueils_da', $routeParams.recueilDaId).get().then(
      (recueilDa) ->
        # breadcrums
        if breadcrumbsGetRecueilDADefer?
          breadcrumbsGetRecueilDADefer.resolve(recueilDa)
          breadcrumbsGetRecueilDADefer = undefined

        if recueilDa.usager_1.identifiant_eurodac?
          $scope.searchIdEnabled = true
        else if recueilDa.usager_2? and recueilDa.usager_2.identifiant_eurodac?
          $scope.searchIdEnabled = true
        else if recueilDa.enfants?
          for enfant in recueilDa.enfants when enfant.identifiant_eurodac?
            $scope.searchIdEnabled = true
            break
        $scope.recueil_da = recueilDa
        $scope.usager_1 = init_usager_for_recueil(recueilDa.statut, "usager1", recueilDa.usager_1)
        checkUsagerExistant($scope.usager_1)
        usagers.push({usager: $scope.usager_1, type_usager: "usager1"})

        if recueilDa.usager_2?
          $scope.usager_2 = init_usager_for_recueil(recueilDa.statut, "usager2", recueilDa.usager_2)
          checkUsagerExistant($scope.usager_2)
          usagers.push({usager: $scope.usager_2, type_usager: "usager2"})

        if recueilDa.enfants?
          for enfant in recueilDa.enfants
            enfant = init_usager_for_recueil(recueilDa.statut, "enfant", enfant)
            checkUsagerExistant(enfant)
            $scope.enfants.push(enfant)
            usagers.push({usager: enfant, type_usager: "enfant"})

        $scope.$watch 'usager_1', ((value) ->
          compute_profil_demande($scope, $scope.recueil_da, is_minor)
          checkEurodac()
        ), true
        $scope.$watch 'usager_2', ((value) ->
          compute_profil_demande($scope, $scope.recueil_da, is_minor)
          checkEurodac()
        ), true
        $scope.$watch 'enfants', ((value) ->
          compute_profil_demande($scope, $scope.recueil_da, is_minor)
          checkEurodac()
        ), true

        params =
          recueil_da: $scope.recueil_da
          profil_demande: $scope.profil_demande
          statut: $scope.statut
          usagers: usagers
          type_usager_label: type_usager_label
        pdf = pdfFactory('recueil_gu', params)
    )

    $scope.addChild = ->
      new_enfant = init_usager_for_recueil($scope.recueil_da.statut, "enfant")
      new_enfant["active"] = true
      $scope.enfants.push(new_enfant)

    $scope.deleteUsager = (usager, type_usager, index_enfant) ->
      if type_usager == "usager2"
        usager.active = false
      else if type_usager == "enfant"
        $scope.enfants.splice(index_enfant, 1)

    $scope.displayUsager2 = ->
      usager = init_usager_for_recueil($scope.recueil_da.statut, "usager2", $scope.usager_2)
      usager.active = true
      $scope.usager_2 = usager

    $scope.cleanForm = ->
      $scope.errors =
        _errors: []
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

    constructRecueilDa = ->
      recueil_da = Backend.all('recueils_da').one($routeParams.recueilDaId)
      if $scope.recueil_da.profil_demande? and $scope.recueil_da.profil_demande != ''
        recueil_da.profil_demande = $scope.recueil_da.profil_demande
      recueil_da.usager_1 = clean_usager_to_save($scope.usager_1)
      if $scope.usager_2.active
        recueil_da.usager_2 = clean_usager_to_save($scope.usager_2)
      recueil_da.enfants = []
      for enfant in $scope.enfants
        enfant_to_save = clean_usager_to_save(enfant)
        recueil_da.enfants.push(enfant_to_save)
      return recueil_da

    $scope.saveRecueil = ->
      confirmSave("save")

    $scope.validateRecueil = ->
      confirmSave("validate")

    $scope.finishRecueil = ->
      confirmSave("finish")

    $scope.validateEuroDacNumberRecueil = ->
      confirmSave("eurodac")

    confirmSave = (action_switch) ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/gu_enregistrement/modal/confirm_save.html'
        controller: 'ModalInstanceGUConfirmSaveController'
        backdrop: false
        keyboard: false
        resolve:
          recueil_da: ->
            return $scope.recueil_da
          action_switch: ->
            return action_switch
      )
      modalInstance.result.then (answer) ->
        if answer
          $scope.working = true
          $scope.cleanForm()
          recueil_da = constructRecueilDa()
          usagers_existants = false
          if recueil_da.usager_1? and recueil_da.usager_1.usager_existant?
            usagers_existants = true
          else if recueil_da.usager_2? and recueil_da.usager_2.usager_existant?
            usagers_existants = true
          else
            for enfant in recueil_da.enfants or [] when enfant.usager_existant?
              usagers_existants = true
          if usagers_existants
            modalUpdateUsagers = $modal.open(
              templateUrl: 'scripts/views/gu_enregistrement/modal/save_usagers_existants.html'
              controller: 'ModalSaveUsagerExistantController'
              backdrop: false
              keyboard: false
              resolve:
                recueil_da: ->
                  return recueil_da
                action_switch: ->
                  return action_switch
            )
            modalUpdateUsagers.result.then (result) ->
              if result.success
                recueilSaved(result.recueil_da, action_switch)
              else
                updateUsagersVersion($scope, recueil_da)
                manageSaveErrors(result.errors, action_switch, result)
          else
            saveRecueil(recueil_da, action_switch)
        else
          if action_switch == "save"
            $scope.saveDone.end?()
          else
            $scope.eurodacDone.end?()
            $scope.validateDone.end?()
          $scope.working = false


    saveRecueil = (recueil_da, action_switch) ->
      recueil_da.put(null, {'if-match': $scope.recueil_da._version}).then(
        (recueil_da) ->
          $scope.recueil_da._version = recueil_da._version
          if action_switch == "save"
            recueilSaved(recueil_da, action_switch)
          else if action_switch == "validate"
            postDemandeursIdentifies(action_switch)
          else if action_switch == "finish"
            postExploite(action_switch)
          else if action_switch == "eurodac"
            postEurodacMiseAJour(action_switch)
        (error) ->
          manageSaveErrors(error, "save")
      )


    postDemandeursIdentifies = (action_switch) ->
      BackendWithoutInterceptor.all('recueils_da/' + $scope.recueil_da.id + '/demandeurs_identifies')
        .post(null, null, null, {'if-match': $scope.recueil_da._version}).then(
          (recueil_da) ->
            recueilSaved(recueil_da, action_switch)
          (error) ->
            manageSaveErrors(error, action_switch)
        )

    postEurodacMiseAJour = (action_switch) ->
      Backend.all("/recueils_da/#{$routeParams.recueilDaId}/generer_eurodac")
        .post(null, null, null, {'if-match': $scope.recueil_da._version}).then(
          (recueil_da) ->
            recueilSaved(recueil_da, action_switch)
          (error) ->
            manageSaveErrors(error, action_switch)
        )

    postExploite = (action_switch) ->
      Backend.all('recueils_da/' + $scope.recueil_da.id + '/exploite')
        .post(null, null, null, {'if-match': $scope.recueil_da._version}).then(
          (recueil_da) ->
            recueilSaved(recueil_da, action_switch)
          (error) ->
            manageSaveErrors(error, action_switch)
        )

    recueilSaved = (recueil_da, action_switch) ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/gu_enregistrement/modal/recueil_saved.html'
        controller: 'ModalInstanceGURecueilSavedController'
        backdrop: false
        keyboard: false
        resolve:
          recueil_da: ->
            return recueil_da
          action_switch: ->
            return action_switch
      )
      modalInstance.result.then (action) ->
        if action == 'list'
          window.location = '#/gu-enregistrement'
        else if action == 'show'
          $route.reload()


    manageSaveErrors = (error, action_switch, usager_infos = null) ->
      $scope.errors =
        _errors: []
      if action_switch == "save"
        $scope.errors._errors.push("Le recueil n'a pas pu être enregistré.")
      else if action_switch == "validate"
        $scope.errors._errors.push("La validation des demandeurs d'asile a échoué.")
      else if action_switch == "eurodac"
        $scope.errors._errors.push("La génération des numéro EURODAC a échoué.")
      else if action_switch == "finish"
        $scope.errors._errors.push("La validation du recueil a échoué.")

      if error.status == 400
        $scope.errors._errors.push("Veuillez vérifier votre saisie.")
        for key, value of error.data
          if key == '_errors'
            for error in value
              if error.usager_1?
                $scope.usager_1._errors = compute_errors(error.usager_1, "Usager 1", $scope.errors._errors)
              else if error.usager_2?
                $scope.usager_2._errors = compute_errors(error.usager_2, "Usager 2", $scope.errors._errors)
              else if error.enfants?
                for s_child_key, s_child_value of error.enfants
                  $scope.enfants[s_child_key]._errors = compute_errors(s_child_value, "Enfant #{parseInt(s_child_key)+1}", $scope.errors._errors)
              else if error.identifiant_famille_dna?
                $scope.errors._errors.push("L'identifiant famille dn@ n'a pas été récupéré.")
              else if typeof(error) == "string" and
                      error.search("le champ identifiant_agdref doit être unique") != -1
                error_split = error.split(" ")
                $scope.errors._errors.push("Le numéro étranger #{error_split[error_split.length-3]} est déjà utilisé par un autre usager existant dans le portail, sélectionnez ce dernier pour enregistrer le recueil.")
              else if error.demandeurs_identifies?
                $scope.errors._errors.push(error.demandeurs_identifies.msg)
              else
                $scope.errors._errors.push(error)
          else if key == 'usager_1'
            $scope.usager_1._errors = compute_errors(value, "Usager 1", $scope.errors._errors)
          else if key == 'usager_2'
            if value == "Un usager secondaire est requis en cas de situation familiale MARIE, CONCUBIN ou PACSE"
              $scope.errors._errors.push(value)
            else if value == "La situation familiale de l'usager principal doit être MARIE, CONCUBIN ou PACSE pour avoir un usager secondaire."
              $scope.errors._errors.push(value)
            else
              $scope.usager_2._errors = compute_errors(value, "Usager 2", $scope.errors._errors)
          else if key == 'enfants'
            for child_key, child_value of value
              $scope.enfants[child_key]._errors = compute_errors(child_value, "Enfant #{parseInt(child_key)+1}", $scope.errors._errors)
          else
            $scope.errors[key] = value

      else if error.status == 412
        if not usager_infos?
          $scope.errors._errors.push("La sauvegarde des modifications est impossible, ce recueil a été modifié entre-temps par un autre utilisateur. Veuillez rafraîchir la page afin de pouvoir sauvegarder votre recueil.")
        else
          text = "La sauvegarde des modifications de "
          if usager_infos.type_usager == "usager_1"
            text += "l'usager 1"
          else if usager_infos.type_usager == "usager_2"
            text += "l'usager 2"
          else if usager_infos.type_usager == "enfant"
            text += "l'enfant #{usager_infos.index_enfant+1}"
          text += " est impossible, cet usager a été modifié entre-temps par un autre utilisateur."
          $scope.errors._errors.push(text)

      else if error.status == 503
        for key, value of error.data
          for elt in value
            $scope.errors._errors.push(elt)

      else
        $scope.errors._errors.push("Une erreur interne est survenue. Merci de contacter votre administrateur")

      $scope.saveDone.end?()
      $scope.validateDone.end?()
      $scope.eurodacDone.end?()
      $scope.working = false


    $scope.printRecueil = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/premier_accueil/modal/select_lang.html'
        controller: 'ModalLanguagesController'
        resolve:
          languages: ->
            return pdf.getLanguages()
      )
      modalInstance.result.then (language) ->
        if language != false
          $scope.working = true
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



  .controller 'NouveauGUEnregistrementController', ($scope, $route, $routeParams, moment,
                                                    $modal, Backend, session,
                                                    SETTINGS, is_minor,
                                                    compute_errors, init_usager_for_recueil,
                                                    clean_usager_to_save) ->
    initWorkingScope($scope, $modal)
    $scope.profil_demande = SETTINGS.PROFIL_DEMANDE
    $scope.recueil_statut = SETTINGS.RECUEIL_STATUT
    $scope.premier_accueil_to_gu = true
    $scope.PERMISSIONS = SETTINGS.PERMISSIONS

    $scope.user = {}
    session.getUserPromise().then (user) ->
      $scope.user = user.plain()
      $scope.site_affecte_id = null
      if user.site_affecte?
        $scope.site_affecte_id = user.site_affecte.id
      else
        return

    $scope.editLocation = true
    $scope.date_entree_en_france = ''
    $scope.date_depart = ''
    $scope.origin_date_entree_en_france = ''
    $scope.origin_date_depart = ''
    $scope.recueil_da =
      profil_demande: ""
      statut: "PA_REALISE"
    $scope.statut = "PA_REALISE"
    $scope.usager_1 = init_usager_for_recueil($scope.recueil_da.statut, "usager1")
    $scope.usager_2 =
      active: false
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
      enfant = init_usager_for_recueil($scope.recueil_da.statut, "enfant")
      $scope.enfants.push(enfant)

    $scope.deleteUsager = (usager, type_usager, index_enfant) ->
      if type_usager == "usager2"
        usager.active = false
      else if type_usager == "enfant"
        $scope.enfants.splice(index_enfant, 1)

    $scope.displayUsager2 = ->
      usager = init_usager_for_recueil($scope.recueil_da.statut, "usager2", $scope.usager_2)
      usager.active = true
      $scope.usager_2 = usager

    $scope.cleanForm = ->
      $scope.errors =
        _errors: []
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
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/gu_enregistrement/modal/confirm_save.html'
        controller: 'ModalInstanceGUConfirmSaveController'
        backdrop: false
        keyboard: false
        resolve:
          recueil_da: ->
            return $scope.recueil_da
          action_switch: ->
            return "save"
      )
      modalInstance.result.then (answer) ->
        if answer
          $scope.cleanForm()
          $scope.recueil_da.usager_1 = clean_usager_to_save($scope.usager_1)
          if $scope.usager_2.active
            $scope.recueil_da.usager_2 = clean_usager_to_save($scope.usager_2)
          $scope.recueil_da.enfants = []
          for enfant in $scope.enfants
            enfant_to_save = clean_usager_to_save(enfant)
            $scope.recueil_da.enfants.push(enfant_to_save)
          Backend.all('recueils_da').post($scope.recueil_da).then(
            (recueil_da) ->
              recueilSaved(recueil_da)
            (error) ->
              manageErrors(error)
          )
        else
          $scope.saveDone.end?()


    recueilSaved = (recueil_da) ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/gu_enregistrement/modal/recueil_saved.html'
        controller: 'ModalInstanceGURecueilSavedController'
        backdrop: false
        keyboard: false
        resolve:
          recueil_da: ->
            return recueil_da
          action_switch: ->
            return "save"
      )
      modalInstance.result.then (action) ->
        if action == 'list'
          window.location = '#/gu-enregistrement'
        else if action == 'rdv'
          window.location = '#/gu-enregistrement/' + recueil_da.id + '/convocation'
        else
          window.location = '#/gu-enregistrement/' + recueil_da.id


    manageErrors = (error, usager_infos = null) ->
      $scope.errors =
        _errors: []
      $scope.errors._errors.push("Le recueil n'a pas pu être enregistré.")

      if error.status == 400
        $scope.errors._errors.push("Veuillez vérifier votre saisie.")
        for key, value of error.data
          if key == '_errors'
            for error in value
              if "L'utilisateur doit avoir un StructureAccueil comme site_affecte pour pouvoir créer un receuil_da" in value
                $scope.errors._errors.push("L'utilisateur doit être rattaché à une structure d'accueil pour pouvoir créer un recueil de demande d'asile")
              else if error.demandeurs_identifies?
                $scope.errors._errors.push(error.demandeurs_identifies.msg)
              else
                $scope.errors._errors.push(error)
          else if key == 'usager_1'
            $scope.usager_1._errors = compute_errors(value, "Usager 1", $scope.errors._errors)
          else if key == 'usager_2'
            if value == "Un usager secondaire est requis en cas de situation familiale MARIE, CONCUBIN ou PACSE"
              $scope.errors._errors.push(value)
            else if value == "La situation familiale de l'usager principal doit être MARIE, CONCUBIN ou PACSE pour avoir un usager secondaire."
              $scope.errors._errors.push(value)
            else
              $scope.usager_2._errors = compute_errors(value, "Usager 2", $scope.errors._errors)
          else if key == 'enfants'
            for child_key, child_value of value
              $scope.enfants[child_key]._errors = compute_errors(child_value, "Enfant #{parseInt(child_key)+1}", $scope.errors._errors)
          else if key == 'profil_demande'
            $scope.errors._errors.push("Ajoutez au moins un usager demandeur.")
          else
            $scope.errors[key] = value
      else if error.status == 412 and usager_infos?
        text = "La sauvegarde des modifications de "
        if usager_infos.type_usager == "usager_1"
          text += "l'usager 1"
        else if usager_infos.type_usager == "usager_2"
          text += "l'usager 2"
        else if usager_infos.type_usager == "enfant"
          text += "l'enfant #{usager_infos.index_enfant+1}"
        text += " est impossible, cet usager a été modifié entre-temps par un autre utilisateur."
        $scope.errors._errors.push(text)
      else
        $scope.errors._errors.push("Une erreur interne est survenue. Merci de contacter votre administrateur")
      $scope.saveDone.end?()



  .controller 'RendezVousHandlerController', ($scope, $route, $routeParams, moment,
                                               $modal, Backend, session, uiCalendarConfig, SETTINGS) ->
    initWorkingScope($scope, $modal)
    ### event sources array###
    $scope.retrieveEventSources = []
    $scope.eventSources = []

    $scope.submitted = false
    $scope.site = {}
    $scope.settingsSite = SETTINGS.SITES
    $scope.newRdv = []
    $scope.nombre_demandeur = 0
    $scope.hasRdv = false
    $scope.motif = ""

    ### A progress bar directive that is focused on providing feedback on the progress
        of a workflow : Retrieve creneaux ###
    $scope.progressbarInfos = {}

    session.getUserPromise().then (user) ->
      $scope.user = user.plain()

    ### Initialize the progressbar ###
    $scope.initProgressbar = ->
      $scope.progressbarInfos =
        value: 0
        index: 0
        nbPages: 0
        show: true


    ### Add a new "creneau" on fullCalendar ###
    $scope.insertCreneauInCalendar = (creneau, retrieve = false) ->
      backgroundColor = if creneau.reserve then '#E83C1A' else '#4EA9A0'
      title = if creneau.marge then 'Marge: ' + creneau.marge + 'min' else ''
      event =
        start: creneau.date_debut
        end: creneau.date_fin
        title: title
        editable: false
        backgroundColor: backgroundColor
        creneau_id: creneau.id
        type: 'creneau'
        reserve: creneau.reserve
        marge: creneau.marge
      if retrieve
        $scope.retrieveEventSources.push(event)
      else
        $scope.eventSources.push([event])


    ### Retrieve "creneaux" ###
    $scope.retrieveCreneaux = (link) ->
      $scope.retrieveCreneauxLoop = (link) ->
        if link
          Backend.all(link).getList().then (creneaux) ->
            if $scope.progressbarInfos.index == 0
              $scope.progressbarInfos.nbPages = Math.ceil(creneaux._meta.total / creneaux._meta.per_page)

            for creneau in creneaux
              $scope.insertCreneauInCalendar(creneau, true)

            $scope.progressbarInfos.index++
            $scope.progressbarInfos.value = Math.ceil(($scope.progressbarInfos.index * 100) / $scope.progressbarInfos.nbPages)
            $scope.retrieveCreneauxLoop(creneaux._links.next)
        else
          $scope.progressbarInfos.show = false
          uiCalendarConfig.calendars.plages.fullCalendar('addEventSource', $scope.retrieveEventSources)

      $scope.retrieveEventSources.length = 0
      $scope.initProgressbar()
      $scope.retrieveCreneauxLoop(link)


    ### Select which "creneaux" will be displayed on fullCalendar ###
    $scope.selectCreneaux = (dateBegin, dateEnd)->
      Backend.one('recueils_da', $routeParams.recueilDaId).get().then(
        (recueil_da) ->
          $scope.recueil_da = recueil_da

          if recueil_da.rendez_vous_gu
            $scope.hasRdv = true
          if recueil_da.usager_1 and recueil_da.usager_1.demandeur
            $scope.nombre_demandeur += 1
          if recueil_da.usager_2 and recueil_da.usager_2.demandeur
            $scope.nombre_demandeur += 1

          if recueil_da.enfants
            for enfant in recueil_da.enfants
              if enfant.demandeur
                $scope.nombre_demandeur += 1

          session.getUserPromise().then(
            (user) ->
              $scope.user = user
              Backend.one(user.site_affecte._links.self).get().then(
                (site) ->
                  # breadcrums1
                  if breadcrumbsGetSiteDefer?
                    breadcrumbsGetSiteDefer.resolve(site)
                    breadcrumbsGetSiteDefer = undefined

                  $scope.retrieveCreneaux('sites/' + site.id + '/creneaux?fq=date_debut:[' + dateBegin + ' TO ' + dateEnd + ']')
              )

            (error) -> window.location = '#/404'
          )
      )


    ### Refresh fullCalendar ###
    $scope.refreshCalendar = ->
      calendarView = uiCalendarConfig.calendars.plages.fullCalendar('getView')

      # Clean calendar
      uiCalendarConfig.calendars.plages.fullCalendar('removeEvents')

      # Get the current date
      today = uiCalendarConfig.calendars.plages.fullCalendar('getDate')
      dateBegin = '=?'
      dateEnd = '=?'

      # Select beginning and end date. These variables will be used to select
      # the specifics "creneaux" that will be print on the calendar.
      if (calendarView.name == "agendaDay")
        dateBegin = today.startOf('day').format('YYYY-MM-DD[T]HH:mm:ss[Z]')
        dateEnd = today.endOf('day').format('YYYY-MM-DD[T]HH:mm:ss[Z]')
      else if (calendarView.name == "agendaWeek")
        dateBegin = today.startOf('week').format('YYYY-MM-DD[T]HH:mm:ss[Z]')
        dateEnd = today.endOf('week').format('YYYY-MM-DD[T]HH:mm:ss[Z]')
      else
        dateBegin = today.startOf('month').format('YYYY-MM-DD[T]HH:mm:ss[Z]')
        dateEnd = today.endOf('month').format('YYYY-MM-DD[T]HH:mm:ss[Z]')

      $scope.selectCreneaux(dateBegin, dateEnd)


    ### Triggered when a new date-range is rendered, or when the view type switches ###
    $scope.viewRender = (view, element) ->
      $scope.refreshCalendar()


    ### Triggered when the user clicks on a day ###
    $scope.eventClick = (event, jsEvent, view) ->
      if event.reserve
        return
      indexEvent = $scope.newRdv.indexOf(event)
      if indexEvent == -1

        if $scope.newRdv.length >= 2
          modalInstance = $modal.open(
            templateUrl: 'scripts/xin/modal/modal.html'
            controller: 'ModalInstanceAlertController'
            backdrop: false
            keyboard: false
            resolve:
              message: ->
                return "Un recueil peut réserver au maximum deux créneaux consécutifs."
          )
        else if $scope.nombre_demandeur <= 1 && $scope.newRdv.length >= 1
          modalInstance = $modal.open(
            templateUrl: 'scripts/xin/modal/modal.html'
            controller: 'ModalInstanceAlertController'
            backdrop: false
            keyboard: false
            resolve:
              message: ->
                return "Un recueil avec un unique demandeur ne peut réserver qu'un seul créneau."
          )
        else if $scope.newRdv.length == 1 && ($scope.newRdv[0].start._i != event.end._i && $scope.newRdv[0].end._i != event.start._i)
          modalInstance = $modal.open(
            templateUrl: 'scripts/xin/modal/modal.html'
            controller: 'ModalInstanceAlertController'
            backdrop: false
            keyboard: false
            resolve:
              message: ->
                return "Les créneaux sélectionnés doivent être consécutifs"
          )
        else
          $scope.newRdv.push(event)
          event.backgroundColor = "orange"
      else
        event.backgroundColor = '#4EA9A0'
        delete $scope.newRdv[indexEvent]
        tmpNewRdv = []
        for rdv in $scope.newRdv
          if rdv
            tmpNewRdv.push(rdv)
        $scope.newRdv = tmpNewRdv
      uiCalendarConfig.calendars.plages.fullCalendar('refetchEvents', event._id)


    ### Upade "rendez-vous" ###
    $scope.updateRdv = ->
      if $scope.newRdv.length == 0 && $scope.hasRdv == true
        modalInstanceAnnule = $modal.open(
          templateUrl: 'scripts/xin/modal/modal.html'
          controller: 'ModalInstanceConfirmController'
          backdrop: false
          keyboard: false
          resolve:
            message: ->
              return "Vous allez annuler ce rendez-vous."
            sub_message: ->
              return ''
        )
        modalInstanceAnnule.result.then (confirm) ->
          if not confirm
            $scope.cancelRdv.end?()
            return
          Backend.all('recueils_da/' + $scope.recueil_da.id + '/rendez_vous').remove(null, {'if-match' : $scope.recueil_da._version}).then(
            (recueil_da) ->
              modalInstance = $modal.open(
                templateUrl: 'scripts/views/gu_enregistrement/modal/modal_gerer_rdv.html'
                controller: 'ModalInstanceGUEditRDVController'
                backdrop: false
                keyboard: false
                resolve:
                  recueil_da: ->
                    return recueil_da
              )
              modalInstance.result.then (action) ->
                if action == 'list'
                  window.location = '#/gu-enregistrement'
                else if action == 'show'
                  window.location = '#/gu-enregistrement/' + $scope.recueil_da.id
            (error) ->
              $scope.cancelRdv.end?()
              $scope.errors = []
              if error.status == 400
                $scope.errors = error.data._errors
              else if error.status == 412
                $scope.errors.push("La sauvegarde des modifications est impossible, ce rendez-vous a été modifié entre-temps par un autre utilisateur. Veuillez rafraîchir la page afin de pouvoir sauvegarder votre recueil.")
              else
                $scope.errors.push("Une erreur innatendue est survenue. Merci de contacter votre administrateur.")
          )
      else
        if $scope.motif == ''
          modalInstance = $modal.open(
            templateUrl: 'scripts/xin/modal/modal.html'
            controller: 'ModalInstanceAlertController'
            backdrop: false
            keyboard: false
            resolve:
              message: ->
                return "Un motif de changement de rendez-vous est nécessaire pour prendre un nouveau rendez-vous."
          )
          modalInstance.result.then ->
            $scope.saveDone.end?()
        else if $scope.newRdv.length == 0
          modalInstance = $modal.open(
            templateUrl: 'scripts/xin/modal/modal.html'
            controller: 'ModalInstanceAlertController'
            backdrop: false
            keyboard: false
            resolve:
              message: ->
                return "Veuillez choisir un ou plusieurs créneaux sur le calendrier pour prendre un nouveau rendez-vous."
          )
          modalInstance.result.then ->
            $scope.saveDone.end?()
        else
          payload =
            motif: $scope.motif
            creneaux: []
          for rdv in $scope.newRdv
            payload.creneaux.push(rdv.creneau_id)
          if $scope.hasRdv
            Backend.all('recueils_da/' + $scope.recueil_da.id + '/rendez_vous').remove(null, {'if-match' : $scope.recueil_da._version}).then(
              (recueil_da) ->
                Backend.all('recueils_da/' + $scope.recueil_da.id + '/rendez_vous').customPUT(payload).then(
                  (recueil_da) ->
                    modalInstance = $modal.open(
                      templateUrl: 'scripts/views/gu_enregistrement/modal/modal_gerer_rdv.html'
                      controller: 'ModalInstanceGUEditRDVController'
                      backdrop: false
                      keyboard: false
                      resolve:
                        recueil_da: ->
                          return recueil_da
                    )
                    modalInstance.result.then((action) ->
                      if action == 'list'
                        window.location = '#/gu-enregistrement'
                      else if action == 'show'
                        window.location = '#/gu-enregistrement/' + $scope.recueil_da.id
                      else if action == 'rdv'
                        window.location = '#/gu-enregistrement/' + $scope.recueil_da.id + '/convocation'
                    )
                  (error) ->
                    $scope.saveDone.end?()
                    $scope.errors = []
                    if error.status == 400
                      if (error.data._errors[0] != "Certains créneaux sont invalides")
                        $scope.errors = error.data._errors
                      else
                        $scope.errors.push("Les créneaux choisis ne sont plus disponibles, merci d'actualiser la page.")
                    else if error.status == 412
                      $scope.errors.push("La sauvegarde des modifications est impossible, ce rendez-vous a été modifié entre-temps par un autre utilisateur. Veuillez rafraîchir la page afin de pouvoir sauvegarder votre recueil.")
                    else
                      $scope.errors.push("Une erreur innatendue est survenue. Merci de contacter votre administrateur.")
                )
              (error) ->
                $scope.saveDone.end?()
                $scope.errors = []
                if error.status == 400
                  $scope.errors = error.data._errors
                else if error.status == 412
                  $scope.errors.push("La sauvegarde des modifications est impossible, ce rendez-vous a été modifié entre-temps par un autre utilisateur. Veuillez rafraîchir la page afin de pouvoir sauvegarder votre recueil.")
                else
                  $scope.errors.push("Une erreur innatendue est survenue. Merci de contacter votre administrateur.")

            )
          else
            Backend.all('recueils_da/' + $scope.recueil_da.id + '/rendez_vous').customPUT(payload, null, null, {'if-match' : $scope.recueil_da._version}).then(
              (recueil_da) ->
                modalInstance = $modal.open(
                  templateUrl: 'scripts/views/gu_enregistrement/modal/modal_gerer_rdv.html'
                  controller: 'ModalInstanceGUEditRDVController'
                  backdrop: false
                  keyboard: false
                  resolve:
                    recueil_da: ->
                      return recueil_da
                )
                modalInstance.result.then((action) ->
                  if action == 'list'
                    window.location = '#/gu-enregistrement'
                  else if action == 'show'
                    window.location = '#/gu-enregistrement/' + $scope.recueil_da.id
                  else if action == 'rdv'
                    window.location = '#/gu-enregistrement/' + $scope.recueil_da.id + '/convocation'
                )

              (error) ->
                $scope.saveDone.end?()
                $scope.errors = []
                if error.status == 400
                  if (error.data._errors[0] != "Certains créneaux sont invalides")
                    $scope.errors = error.data._errors
                  else
                    $scope.errors.push("Les créneaux choisis ne sont plus disponibles, merci d'actualiser la page.")
                else if error.status == 412
                  $scope.errors.push("La sauvegarde des modifications est impossible, ce rendez-vous a été modifié entre-temps par un autre utilisateur. Veuillez rafraîchir la page afin de pouvoir sauvegarder votre recueil.")
                else
                  $scope.errors.push("Une erreur innatendue est survenue. Merci de contacter votre administrateur.")

            )


    ### config object ###
    $.uiCalendarConfig = uiCalendarConfig
    $scope.uiConfig = calendar:
      lang: 'fr'
      timezone: 'local'
      allDaySlot: false
      slotDuration: '00:15:00'
      axisFormat: "HH(:mm)"
      snapMinutes: 15
      columnFormat: 'ddd D'
      height: 650
      firstHour: 8
      displayEventEnd: true
      handleWindowResize: true
      editable: true
      scrollTime: "08:00:00"
      minTime: "06:00:00"
      maxTime: "20:00:00"
      buttonText:
        today: "Aujourd'hui"
        month: "Mois"
        week: "Semaine"
        day: "Jour"
      header:
        left: 'agendaDay agendaWeek month'
        center: 'title',
        right: 'today prev,next'
      titleFormat:
        agendaWeek: "MMM YYYY"
        day: "DD MMM YYYY"
      businessHours: true
      defaultView: 'agendaWeek',
      viewRender: $scope.viewRender
      eventClick: $scope.eventClick



  .directive 'usagerPARealiseDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/views/gu_enregistrement/directive/pa_realise_usager.html'
    controller: 'UsagerController'
    scope:
      usager: '=?'
      typeUsager: '=?'
      indexEnfant: '=?'
      deleteButton: '=?'
      deleteMe: '=?'
      editLocation: '=?'
      profilDemande: '=?'
      uDisabled: '=?'
      adresseReference: '=?'
      paysTraversesReference1: '=?'
      paysTraversesReference2: '=?'
      activeUsagerResearch: '=?'
      recueilStatut: '=?'
      isCollapsed: '=?'
      searchIdEnabled: '=?'
    link: (scope, elem, attrs) ->
      scope.showMore = false
      scope.showMoreIcon = "plus"
      scope.handleShowMore = ->
        scope.showMore = !scope.showMore
        if scope.showMore == true
          scope.showMoreIcon = "minus"
        else
          scope.showMoreIcon = "plus"


  .directive 'usagerDemandeursIdentifiesDirective', (SETTINGS) ->
    restrict: 'E'
    templateUrl: 'scripts/views/gu_enregistrement/directive/demandeurs_identifies_usager.html'
    controller: 'UsagerController'
    scope:
      usager: '=?'
      typeUsager: '=?'
      indexEnfant: '=?'
      deleteButton: '=?'
      deleteMe: '=?'
      disabled: '=?'
      editLocation: '=?'
      profilDemande: '=?'
      uDisabled: '=?'
      activeUsagerResearch: '=?'
      recueilStatut: '=?'
      adresseReference: '=?'
      paysTraversesReference1: '=?'
      paysTraversesReference2: '=?'
      isCollapsed: '=?'
    link: (scope, elem, attrs) ->
      scope.conditionEntreeFrance = SETTINGS.CONDITION_ENTREE_EN_FRANCE
      scope.motifsConditionsExceptionnellesAccueil = SETTINGS.CONDITIONS_EXCEPTIONNELLES_ACCUEIL
      scope.showMore = false
      scope.showMoreIcon = "plus"

      scope.handleShowMore = ->
        scope.showMore = !scope.showMore
        if scope.showMore == true
          scope.showMoreIcon = "minus"
        else
          scope.showMoreIcon = "plus"

      if !scope.usager.identifiant_agdref?
        scope.showMoreEC = true
        scope.showMoreECIcon = "minus"
      else
        scope.showMoreEC = false
        scope.showMoreECIcon = "plus"

      scope.handleShowMoreEC = ->
        scope.showMoreEC = !scope.showMoreEC
        if scope.showMoreEC == true
          scope.showMoreECIcon = "minus"
        else
          scope.showMoreECIcon = "plus"
