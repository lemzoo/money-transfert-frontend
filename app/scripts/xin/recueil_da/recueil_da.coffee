'use strict'

initWorkingScope = (scope, $modal) ->
  scope.working = false
  scope.cancelRecueilDone = {}
  scope.workingModal = ->
    modalInstance = $modal.open(
      templateUrl: 'scripts/xin/modal/modal.html'
      controller: 'ModalInstanceAlertController'
      resolve:
        message: -> return "Un traitement est en cours."
    )


angular.module('xin.recueil_da', ['app.settings', 'ngRoute', 'ui.bootstrap', 'xin.print',
                                  'angularMoment', 'xin.recueil_da.modal',
                                  'xin.listResource', 'xin.tools', 'sc-toggle-switch',
                                  'xin.session', 'xin.backend', 'xin.form', 'xin.referential',
                                  'xin.fpr_service',
                                  'app.views.premier_accueil.modal', 'xin.uploadFile',
                                  'angular-bootstrap-select', 'xin.approchants.modal'])
  .controller 'UsagerController', ($scope, $modal, $location, Backend,
                                   BackendWithoutInterceptor, SETTINGS, session,
                                   moment, DelayedEvent, is_minor,
                                   getUsagerFpr, bindUsagerFne,
                                   bindUsagerFneIds, bindUsagerExistant,
                                   bindUsagerExistantIds) ->
    if $location.path() == "/gu-enregistrement/nouveau-recueil"
      $scope.premier_accueil_to_gu = true
    $scope.panel_id = parseInt(Math.random() * 1000000000)
    $scope.uploader_documents = {}
    $scope.minor_child = false
    $scope.api_url = SETTINGS.API_BASE_URL
    $scope.situation_familiale = SETTINGS.SITUATION_FAMILIALE
    $scope.selectOrigineNom = SETTINGS.ORIGINE_NOM
    $scope.selectTypeDemande = SETTINGS.TYPE_DEMANDE
    $scope.selectMotifRefus = [
      id: "DEUXIEME_DEMANDE_REEXAMEN"
      libelle: "Deuxième demande de réexamen ou réexamen ultérieur"
    ]
    first_load = true

    $scope.selectTypeProcedure = [
      { id: 'NORMALE', libelle: 'Normale' },
      { id: 'ACCELEREE', libelle: 'Accélérée' },
      { id: 'DUBLIN', libelle: 'Dublin' }
    ]

    checkDecisionSurAttestation = ->
      if $scope.usager.type_demande in ["PREMIERE_DEMANDE_ASILE", "REOUVERTURE_DOSSIER"]
        $scope.usager.decision_sur_attestation = true
      else
        $scope.usager.type_procedure = "ACCELEREE"
        $scope.selectMotifQualification = SETTINGS.QUALIFICATION[$scope.usager.type_procedure]
        $scope.usager.motif_qualification_procedure = "REEX"
        if parseInt($scope.usager.numero_reexamen) == 1
          $scope.usager.decision_sur_attestation = true
        else
          $scope.usager.decision_sur_attestation = false
          $scope.usager.refus =
            motif: "DEUXIEME_DEMANDE_REEXAMEN"
            date_notification: moment()._d

    checkTypeProcedure = ->
      if $scope.usager.type_demande in ["PREMIERE_DEMANDE_ASILE", "REOUVERTURE_DOSSIER"]
        $scope.usager.motif_qualification_procedure = null
        $scope.selectMotifQualification = [{id:null, libelle: 'Commencez par choisir un type de procédure'}]
        if $scope.usager.type_procedure? and $scope.usager.type_procedure != ""
          $scope.selectMotifQualification = SETTINGS.QUALIFICATION[$scope.usager.type_procedure]

    if $scope.recueilStatut == "DEMANDEURS_IDENTIFIES"
      $scope.$watch 'usager.type_demande', () ->
        checkDecisionSurAttestation()
      $scope.$watch 'usager.numero_reexamen', () ->
        checkDecisionSurAttestation()
      $scope.$watch 'usager.type_procedure', () ->
        checkTypeProcedure()

    # Listen for visa to set indicateur_visa_long_sejour
    $scope.$watch 'usager.visa', (value) ->
      if value == 'AUCUN'
        $scope.usager.indicateur_visa_long_sejour = false
      else if value == 'C'
        $scope.usager.indicateur_visa_long_sejour = false
      else if value == 'D'
        $scope.usager.indicateur_visa_long_sejour = true

    $scope.showFPR = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/gu_enregistrement/modal/fpr.html'
        controller: 'ModalInstanceFPRController'
        resolve:
          fpr_usagers: ->
            return $scope.fpr_usagers
      )

    $scope.showApprochants = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/recueil_da/modal/approchants.html'
        controller: 'ModalApprochantsController'
        resolve:
          usager: ->
            return $scope.usager
      )
      modalInstance.result.then(
        (result) ->
          if result.type == 'pf'
            $scope.usager.usager_existant =
              id: result.usager.id
              _version: result.usager._version
            if result.ec
              bindUsagerExistant(result.usager, $scope.usager)
            else
              bindUsagerExistantIds(result.usager, $scope.usager)
          else if result.type == 'fne'
            if result.ec
              bindUsagerFne(result.usager, $scope.usager)
            else
              bindUsagerFneIds(result.usager, $scope.usager)
          $scope.usager.identite_approchante_select = true
          searchApprochants()
      )


    $scope.showHistoriqueDA = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/gu_enregistrement/modal/historique_da.html'
        controller: 'ModalHistoriqueDAController'
        resolve:
          usager: ->
            return $scope.usager
      )
      modalInstance.result.then(
        (recommendations) ->
          $scope.usager.type_demande = recommendations.type_demande
          $scope.usager.numero_reexamen = recommendations.numero_reexamen
      )


    searchApprochants = ->
      session.getUserPromise().then (user) ->
        if user.role in ['SUPPORT_NATIONAL', "GESTIONNAIRE_NATIONAL",
                         "RESPONSABLE_GU_DT_OFII", "GESTIONNAIRE_GU_DT_OFII"] or
           not $scope.usager? or $scope.usager.inactive
          return
        if $scope.recueilStatut != "ANNULE" and
           $scope.usager.identite_approchante_select
          getFpr()


    $scope.has_fpr_usagers = false
    $scope.no_fpr = false
    fpr_usagers = null
    getFpr = ->
      $scope.fpr_spinner = true
      getUsagerFpr($scope.usager).then(
        (result) ->
          $scope.has_fpr_usagers = result.has_fpr_usagers
          $scope.no_fpr = result.no_fpr
          fpr_usagers = result.fpr_usagers
          $scope.fpr_spinner = false
        () -> $scope.fpr_spinner = false
      )


    if $scope.recueilStatut == "PA_REALISE"
      delayedEvent = new DelayedEvent(1000)
      $scope.$watch 'usager.nom', (value, old_value) ->
        delayedEvent.triggerEvent ->
          if value != old_value
            searchApprochants()
      $scope.$watch 'usager.prenoms', (value, old_value) ->
        if not angular.equals(value, old_value)
          searchApprochants()
      , true
      $scope.$watch 'usager.date_naissance', (value, old_value) ->
        delayedEvent.triggerEvent ->
          if value != old_value
            searchApprochants()
      $scope.$watch 'usager.sexe', (value, old_value) ->
        if value != old_value
          searchApprochants()


    $scope.$watch 'usager.date_naissance', (value) ->
      $scope.minor_child = is_minor(value)
      if $scope.minor_child
        if $scope.typeUsager == 'usager1'
          $scope.profilDemande = 'MINEUR_ISOLE'
        else
          $scope.profilDemande = 'MINEUR_ACCOMPAGNANT'
      else
        $scope.usager.representant_legal_nom = null
        $scope.usager.representant_legal_prenom = null
        $scope.usager.representant_legal_personne_morale = undefined
        $scope.usager.representant_legal_personne_morale_designation = null

    # Clean usager fields when we click on the "demandeur" button
    $scope.$watch 'usager.demandeur', (value, old_value) ->
      if !$scope.usager.usager_existant
        if value
          $scope.usager.present_au_moment_de_la_demande = true
          if (old_value? && !old_value)
            $scope.usager.photo_premier_accueil = undefined
            $scope.usager.photo = undefined
        else
          if (old_value)
            $scope.usager.present_au_moment_de_la_demande = undefined
          $scope.usager.nom_pere = null
          $scope.usager.prenom_pere = null
          $scope.usager.nom_mere = null
          $scope.usager.prenom_mere = null
          $scope.usager.date_entree_en_france = null
          $scope.usager.date_depart = null
          $scope.usager.pays_traverses = []
          $scope.usager.telephone = null
          $scope.usager.email = null
          $scope.usager.photo_premier_accueil = null
          $scope.usager.photo = null
          $scope.usager.langues = []
          $scope.usager.langues_audition_OFPRA = []
          $scope.usager.representant_legal_nom = null
          $scope.usager.representant_legal_prenom = null
          $scope.usager.representant_legal_personne_morale = undefined
          $scope.usager.representant_legal_personne_morale_designation = null
      else
        if value
          $scope.usager.present_au_moment_de_la_demande = true
        else
          if (old_value)
            $scope.usager.present_au_moment_de_la_demande = undefined

    $scope.$watch 'usager', (value) ->
      $scope.origin_usager = {}
      for key, value of $scope.usager
        $scope.origin_usager[key] = value
      $scope.origin_usager.prenoms = []
      for prenom in $scope.usager.prenoms
        $scope.origin_usager.prenoms.push(prenom)
      if not $scope.usager.pays_traverses?
        $scope.usager.pays_traverses = []
      if not $scope.usager.type_demande?
        $scope.usager.type_demande = "PREMIERE_DEMANDE_ASILE"


      $scope.$watch 'usager.situation_familiale', (value) ->
        if value == ""
          $scope.usager.situation_familiale = undefined
      , true

    if not $scope.usager.prenoms?
      $scope.usager.prenoms = []

    $scope.type_usager_label =
      usager1: "Usager 1"
      usager2: "Usager 2"
      enfant: "Enfant"

    $scope.changeLocation = ->
      $scope.editLocation = true

    $scope.useAdresseReference = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return "Vous allez importer l'adresse de l'usager 1."
          sub_message: ->
            return "Voulez-vous continuer?"
      )
      modalInstance.result.then(
        (result) ->
          if result == true
            $scope.usager.adresse = angular.copy($scope.adresseReference)
      )


    $scope.usePaysTraversesReference1 = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return "Vous allez importer les pays traversés de l'usager 1."
          sub_message: ->
            return "Voulez-vous continuer?"
      )
      modalInstance.result.then(
        (result) ->
          if result == true
            $scope.usager.pays_traverses = angular.copy($scope.paysTraversesReference1)
      )

    $scope.usePaysTraversesReference2 = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return "Vous allez importer les pays traversés de l'usager 2."
          sub_message: ->
            return "Voulez-vous continuer?"
      )
      modalInstance.result.then(
        (result) ->
          if result == true
            $scope.usager.pays_traverses = angular.copy($scope.paysTraversesReference2)
      )



  .directive 'cancelRecueilDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/recueil_da/directive/cancel.html'
    controller: 'CancelRecueilController'
    scope:
      recueilDa: '=?'
      urlBack: '=?'
      error: '=?'
    link: (scope, elem, attrs) ->
      return


  .controller 'CancelRecueilController', ($scope, Backend, $modal, SETTINGS, moment) ->
    initWorkingScope($scope, $modal)
    $scope.cancelRecueil = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/recueil_da/modal/cancel_recueil.html'
        controller: 'ModalInstanceConfirmCancelController'
        backdrop: false
        keyboard: false
      )
      modalInstance.result.then (motif) ->
        if motif != false
          Backend.all('recueils_da/' + $scope.recueilDa.id + '/annule').post({"motif" : motif}).then(
            modalInstance = $modal.open(
              templateUrl: 'scripts/xin/modal/modal.html'
              controller: 'ModalInstanceForceConfirmController'
              backdrop: false
              keyboard: false
              resolve:
                message: ->
                  return "Le recueil a bien été annulé."
                sub_message: ->
                  return "Vous allez être redirigé à la liste des recueils."
            )
            modalInstance.result.then (result) ->
              if result == true
                window.location = $scope.urlBack
          )
        else
          $scope.cancelRecueilDone.end?()



  .directive 'rdvConvocationDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/recueil_da/directive/rdv_convocation.html'
    controller: 'RdvConvocationController'
    scope:
      usagers: '=?'
      site: '=?'
      dateConvocation: '=?'
      currentSite: '=?'
      spa: '=?'
    link: (scope, elem, attrs) ->
      return

  .controller 'RdvConvocationController', ($scope, Backend, session, $modal, SETTINGS,
                                           moment, $routeParams, is_minor) ->
    $scope.recueil_da = {}
    $scope.site = {}
    $scope.today = new Date()
    $scope.currentSite = {}
    $scope.api_url = SETTINGS.API_BASE_URL
    $scope.spa = {}

    Backend.one('recueils_da', $routeParams.recueilDaId).get().then(
      (recueilDa) ->
        # breadcrums
        if breadcrumbsGetRecueilDADefer?
          breadcrumbsGetRecueilDADefer.resolve(recueilDa)
          breadcrumbsGetRecueilDADefer = undefined

        session.getUserPromise().then(
          (user) ->
            if user.site_affecte?
              Backend.one('sites', user.site_affecte.id).get().then(
                (site) ->
                  $scope.currentSite = site
                  if recueilDa.rendez_vous_gu_anciens? and recueilDa.rendez_vous_gu_anciens.length
                    $scope.spa = site
                  else
                    Backend.one('sites', $scope.recueil_da.structure_accueil.id).get().then(
                      (site) ->
                        $scope.spa = site.plain()
                    )
              )
        )

        if recueilDa.usager_1? and recueilDa.usager_1.demandeur
          recueilDa.usager_1['enfants'] = 0
          recueilDa.usager_1['enfants_14'] = 0
          $scope.usagers.push(recueilDa.usager_1)
        if recueilDa.usager_2? and recueilDa.usager_2.demandeur
          recueilDa.usager_2['enfants'] = 0
          recueilDa.usager_2['enfants_14'] = 0
          $scope.usagers.push(recueilDa.usager_2)
        for enfant in recueilDa.enfants or []
          if enfant.demandeur
            $scope.usagers.push(enfant)

        if recueilDa.enfants
          for enfant in recueilDa.enfants
            if enfant.demandeur or enfant.present_au_moment_de_la_demande
              has14 = false
              moment_birthday = moment(enfant.date_naissance)
              moment_today = moment()
              diffYear = moment_today.diff(moment_birthday, 'years')
              if diffYear >= 14
                has14 = true

              if enfant.usager_1 and recueilDa.usager_1?
                recueilDa.usager_1.enfants += 1
                if has14
                  recueilDa.usager_1.enfants_14 += 1
              if enfant.usager_2 and recueilDa.usager_2?
                recueilDa.usager_2.enfants += 1
                if has14
                  recueilDa.usager_2.enfants_14 += 1

        $scope.recueil_da = recueilDa
        $scope.dateConvocation = recueilDa.rendez_vous_gu.date

        if recueilDa.rendez_vous_gu.marge?
          moment = moment($scope.dateConvocation)
          moment.subtract(recueilDa.rendez_vous_gu.marge, 'minutes')
          $scope.dateConvocation = moment._d

        if $scope.recueil_da.rendez_vous_gu?
          Backend.one('sites', recueilDa.rendez_vous_gu.site.id).get().then(
            (site) ->
              $scope.site = site.plain()
          )
        else
          window.location = '#/404'
    )



  .directive 'convocationDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/recueil_da/directive/convocation.html'
    controller: 'ConvocationController'
    scope:
      site: '=?'
      usager: '=?'
      apiUrl: '=?'
      dateConvocation: '=?'
      currentSite: '=?'
      today: '=?'
      spa: '=?'
    link: (scope, elem, attrs) ->
      scope.$watch 'usager.date_naissance', (value, old_value) ->
        if value != undefined
          moment_birthday = moment(value)
          moment_today = moment()
          diffYear = moment_today.diff(moment_birthday, 'years')
          if diffYear < 18
            scope.isMinor = true
      return
