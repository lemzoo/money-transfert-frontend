'use strict'


angular.module('xin.usager', ['app.settings', 'ui.bootstrap', 'xin.print',
                              'angularMoment', 'xin.recueil_da.modal',
                              'xin.listResource', 'xin.tools',
                              'xin.session', 'xin.backend', 'xin.form', 'xin.referential',
                              'app.views.premier_accueil.modal', 'xin.uploadFile',
                              'angular-bootstrap-select', 'sc-toggle-switch'])
  .directive 'usagerPfDirective', () ->
    restrict: 'E'
    controller: 'usagerPfController'
    templateUrl: 'scripts/views/usager/directive/usager.html'
    scope:
      usager: '=?'
      originUsager: '=?'
      uDisabled: '=?'
      changeAddress: '=?'
      addressDone: '=?'
    link: (scope, elem, attrs) ->
      return


  .controller 'usagerPfController', ($scope, $filter, $routeParams, SETTINGS,
                                     Backend, BackendWithoutInterceptor) ->
    $scope.CONDITION_ENTREE_EN_FRANCE = SETTINGS.CONDITION_ENTREE_EN_FRANCE
    $scope.CONDITIONS_EXCEPTIONNELLES_ACCUEIL = SETTINGS.CONDITIONS_EXCEPTIONNELLES_ACCUEIL
    $scope.DA_STATUT = SETTINGS.DA_STATUT
    $scope.DECISION_DEFINITIVE_NATURE = SETTINGS.DECISION_DEFINITIVE_NATURE
    $scope.DECISION_DEFINITIVE_RESULTAT = SETTINGS.DECISION_DEFINITIVE_RESULTAT
    $scope.ORIGINE_NOM = SETTINGS.ORIGINE_NOM
    $scope.SOUS_TYPE_DOCUMENT = SETTINGS.SOUS_TYPE_DOCUMENT
    $scope.TYPE_DOCUMENT = SETTINGS.TYPE_DOCUMENT
    $scope.TYPE_PROCEDURE = SETTINGS.TYPE_PROCEDURE
    $scope.TYPE_DEMANDE = SETTINGS.TYPE_DEMANDE
    $scope.demandeur = false
    $scope.demandes_asile = []
    $scope.conjoint = null
    $scope.pere = null
    $scope.mere = null
    $scope.enfants = []
    $scope.minor_child = false
    $scope.portail = undefined
    $scope.lieux_delivrance = {}
    $scope.localisations = null
    $scope.overall = $routeParams.overall?

    # Use to know if we are on overall or local view
    url_overall = if $routeParams.overall? then '?overall' else ''
    url_separator = if $routeParams.overall? then '&' else '?'
    url_usager = "fq=usager_r:#{$scope.usager.id}"

    $scope.$watch "usager", (usager) ->
      if usager?.id?
        url_usager = "fq=usager_r:#{usager.id}"

        usager.langues = usager.langues or []
        usager.langues_audition_OFPRA = usager.langues_audition_OFPRA or []
        getFamilyMember("pere", usager.identifiant_pere)
        getFamilyMember("mere", usager.identifiant_mere)
        getFamilyMember("conjoint", usager.conjoint)
        getLocalisation("usagers/#{usager.id}/localisations#{url_overall}#{url_separator}per_page=10")
        getDemandesAsile()
        Backend.one("usagers/#{usager.id}/enfants").get().then (l_enfants) ->
          for enfant in l_enfants.enfants
            getEnfant(enfant)

        $scope.$watch 'usager.date_naissance', (value) ->
          if value? and value != ''
            moment_birthday = moment(value)
            if moment_birthday.isValid()
              moment_today = moment()
              diffYear = moment_today.diff(moment_birthday, 'years')
              if diffYear < 18
                $scope.minor_child = true
              else
                $scope.minor_child = false
                $scope.usager.representant_legal_nom = null
                $scope.usager.representant_legal_prenom = null
                $scope.usager.representant_legal_personne_morale = undefined
                $scope.usager.representant_legal_personne_morale_designation = null
            else
              $scope.minor_child = false
          else
            $scope.minor_child = false

    getDemandesAsile = () ->
      Backend.all("demandes_asile#{url_overall}#{url_separator}#{url_usager}").getList().then (demandes_asile) ->
        $scope.demandes_asile = demandes_asile.plain()
        if demandes_asile.plain().length > 0
          $scope.demandeur = true
        for demande_asile in $scope.demandes_asile
          demande_asile.droits = []
          demande_asile.nb_en_renouvellement = 0
          demande_asile.decision_definitive = null
          if demande_asile.decisions_definitives?.length
            demande_asile.decision_definitive = demande_asile.decisions_definitives[demande_asile.decisions_definitives.length-1]
          demande_asile.recevabilite = null
          if demande_asile.recevabilites?.length
            demande_asile.recevabilite = demande_asile.recevabilites[demande_asile.recevabilites.length-1]
        getDroits()

    getDroits = () ->
      Backend.all("droits#{url_overall}#{url_separator}#{url_usager}").getList().then (droits) ->
        for droit in droits.plain()
          for da in $scope.demandes_asile when da.id == droit.demande_origine.id.toString()
            if droit.sous_type_document == "EN_RENOUVELLEMENT"
              da.nb_en_renouvellement++
            for support in droit.supports or []
              $scope.lieux_delivrance[support.lieu_delivrance.id] = ""
            da.droits.push(droit)
        getLieuxDelivrance()

    getLieuxDelivrance = () ->
      for lieu of $scope.lieux_delivrance
        getLieuDelivrance(lieu)

    getLieuDelivrance = (site_id) ->
      Backend.one("sites/#{site_id}").get().then(
        (site) ->
          $scope.lieux_delivrance[site.id] = site.libelle
      )

    getFamilyMember = (member_type, identifiant_member) ->
      if identifiant_member?
        route_membre = "usagers/#{identifiant_member.id}#{url_overall}"
        BackendWithoutInterceptor.one(route_membre).get().then(
          (member) ->
            $scope[member_type] = member
          (error) ->
            if error.status == 403
              Backend.one("usagers/#{identifiant_member.id}/prefecture_rattachee").get().then(
                (member) ->
                  Backend.one(member.prefecture_rattachee._links.self).get().then(
                    (prefecture) ->
                      $scope[member_type] = {'prefecture_rattachee' : prefecture, 'usager_id' : identifiant_member.id}
                  )
              )
        )

    getEnfant = (enfant) ->
      BackendWithoutInterceptor.one("usagers/#{enfant}#{url_overall}").get().then(
        (b_enfant) ->
          $scope.enfants.push(b_enfant)
        (error) ->
          if error.status == 403
            Backend.one("usagers/#{enfant}/prefecture_rattachee").get().then(
              (usager) ->
                Backend.one(usager.prefecture_rattachee._links.self).get().then(
                  (prefecture) ->
                    $scope.enfants.push({'prefecture_rattachee': prefecture, 'usager_id': enfant})
                )
            )
      )

    getLocalisation = (url) ->
      Backend.all(url).getList().then (localisations) ->
        for localisation in localisations
          if localisation.organisme_origine == "PORTAIL"
            $scope.portail = angular.copy(localisation)
          else if not $scope.localisations?[localisation.organisme_origine]? or
                  $scope.localisations[localisation.organisme_origine].date_maj < localisation.date_maj
            $scope.localisations = $scope.localisations or {}
            $scope.localisations[localisation.organisme_origine] = angular.copy(localisation)
        if localisations._meta.next
          getLocalisation(localisations._meta.next)
