"use strict"

angular.module('xin.approchants.modal', ['xin.fne_service'])
  .controller 'ModalApprochantsController', ($scope, $modalInstance, $q, $sce,
                                             BackendWithoutInterceptor,
                                             usager, getUsagersFne,
                                             retrieveFneUsager) ->
    $scope.usager = usager
    $scope.usager_search =
      identifiant_agdref: ""
      identifiant_eurodac: []
      nom: usager.nom
      prenoms: []
      sexe: usager.sexe
      date_naissance: usager.date_naissance
    angular.copy(usager.prenoms, $scope.usager_search.prenoms)
    $scope.searched = false
    $scope.searchDone = {}
    $scope.usager_orig = usager

    $scope.initModal = () ->
      height = window.innerHeight-70
      angular.element(document).find('.modal-dialog').css("max-height", "#{height}px")
      angular.element(document).find('.modal-dialog').css("overflow-y", "auto")

    init_scope = ->
      $scope.fne_cr206 = false
      $scope.no_fne = false
      $scope.pf_usagers_agdref = []
      $scope.fne_usagers_agdref = []
      $scope.pf_usagers_eurodac = []
      $scope.fne_usagers_eurodac = []
      $scope.pf_usagers_ec = []
      $scope.fne_usagers_ec = []
    init_scope()

    $scope.search = ->
      init_scope()
      searchIdAgdref().then () ->
        searchIdEurodac().then () ->
          searchCivilStatus().then () ->
            _check_diff()
            $scope.searched = true
            $scope.searchDone.end()

    searchIdAgdref = ->
      defer = $q.defer()
      if not $scope.usager_search.identifiant_agdref? or $scope.usager_search.identifiant_agdref == ""
        defer.resolve()
        return defer.promise
      url = "/recherche_usagers_tiers?usagers=true&identifiant_agdref=#{$scope.usager_search.identifiant_agdref}"
      BackendWithoutInterceptor.one(url).get().then(
        (items) ->
          _retrieve_pf_usagers(items['PLATEFORME'], $scope.pf_usagers_agdref).then () ->
            retrieveFneUsager($scope.usager_search.identifiant_agdref).then(
              (fne_usager) ->
                if fne_usager.identifiant_agdref?
                  $scope.fne_usagers_agdref = [fne_usager]
                for usager_fne in $scope.fne_usagers_agdref
                  usager_fne.active = true
                  for usager_portail in $scope.pf_usagers_agdref
                    if usager_fne.identifiant_agdref == usager_portail.identifiant_agdref
                      usager_fne.active = false
                      break
                defer.resolve()
              (error) -> defer.resolve()
            )
        (error) ->
          defer.resolve()
      )
      return defer.promise

    searchIdEurodac = ->
      defer = $q.defer()
      if not $scope.usager_search.identifiant_eurodac.length
        defer.resolve()
        return defer.promise
      fq_eurodac = "identifiants_eurodac=("
      for id, i in $scope.usager_search.identifiant_eurodac
        if i == 0
          fq_eurodac += id
        else
          fq_eurodac += " OR #{id}"
      fq_eurodac += ")"
      url = "/recherche_usagers_tiers?usagers=true&#{fq_eurodac}"
      BackendWithoutInterceptor.one(url).get().then(
        (items) ->
          if items['PLATEFORME']
            _retrieve_pf_usagers(items['PLATEFORME'], $scope.pf_usagers_eurodac).then () ->
              defer.resolve()
        (error) ->
          defer.resolve()
      )
      return defer.promise

    searchCivilStatus = ->
      defer = $q.defer()
      getUsagersFne($scope.usager_search).then(
        (result) ->
          $scope.fne_cr206 = result.fne_cr206
          $scope.no_fne = result.no_fne
          _retrieve_pf_usagers(result.pf_usagers, $scope.pf_usagers_ec).then () ->
            _retrieve_fne_usagers(result.fne_usagers, $scope.fne_usagers_ec).then () ->
              defer.resolve()
        () ->
          defer.resolve()
      )
      return defer.promise

    _retrieve_pf_usagers = (pf_usagers, dest) ->
      defer = $q.defer()
      promises = []
      for usager in pf_usagers
        promise = _retrieve_pf_usager(usager, dest)
        promises.push(promise)
      $q.all(promises).then(
        () -> defer.resolve()
      )
      return defer.promise

    _retrieve_pf_usager = (pf_usager, dest) ->
      defer = $q.defer()
      BackendWithoutInterceptor.one("/usagers/#{pf_usager.id}").get().then(
        (usager) ->
          BackendWithoutInterceptor.all("/demandes_asile?fq=usager:#{usager.id}&sort=date_demande desc").getList().then(
            (demandes_asiles) ->
              if demandes_asiles.plain().length
                last_da = demandes_asiles.plain()[0]
                if last_da.statut not in ["DECISION_DEFINITIVE", "FIN_PROCEDURE_DUBLIN", "FIN_PROCEDURE"]
                  usager.indicateurDecisionDefinitive = 'O'
              dest.push(usager)
              defer.resolve()
            (error) -> defer.resolve()
          )
        (error) ->
          if error.status == 403
            BackendWithoutInterceptor.one("/usagers/#{pf_usager.id}/prefecture_rattachee").get().then(
              (usager) ->
                BackendWithoutInterceptor.one(usager.prefecture_rattachee._links.self).get().then(
                  (prefecture) ->
                    pf_usager.contact_prefecture_rattachee = prefecture
                    dest.push(pf_usager)
                    defer.resolve()
                  (error) -> defer.resolve()
                )
              (error) -> defer.resolve()
            )
      )
      return defer.promise

    _retrieve_fne_usagers = (fne_usagers, dest) ->
      defer = $q.defer()
      promises = []
      for usager in fne_usagers
        promise = _retrieve_fne_usager(usager, dest)
        promises.push(promise)
      $q.all(promises).then(
        () -> defer.resolve()
      )
      return defer.promise

    _retrieve_fne_usager = (fne_usager, dest) ->
      defer = $q.defer()
      retrieveFneUsager(fne_usager).then(
        (usager) ->
          usager.active = true
          for pf_usager in $scope.pf_usagers_ec
            if pf_usager.identifiant_agdref == fne_usager
              usager.active = false
          $scope.fne_usagers_ec.push(usager)
          defer.resolve()
        (error) -> defer.resolve()
      )
      return defer.promise

    $scope.cancel = ->
      $modalInstance.dismiss('cancel')

    $scope.selectApprochant = (type, usager) ->
      $modalInstance.close({type: type, usager: usager, ec: true})

    $scope.selectApprochantWithoutEC = (type, usager) ->
      $modalInstance.close({type: type, usager: usager, ec: false})

    # check if at least one field differed
    _check_diff = () ->
      for usager in $scope.pf_usagers_agdref
        _check_diff_usager(usager)
      for usager in $scope.fne_usagers_agdref
        _check_diff_usager(usager)
      for usager in $scope.pf_usagers_eurodac
        _check_diff_usager(usager)
      for usager in $scope.fne_usagers_eurodac
        _check_diff_usager(usager)
      for usager in $scope.pf_usagers_ec
        _check_diff_usager(usager)
      for usager in $scope.fne_usagers_ec
        _check_diff_usager(usager)

    _check_diff_usager = (usager) ->
      usager.at_least_one_diff = false
      usagerdate = moment(usager.date_naissance).utc().format("DD/MM/YYYY")
      usager.date_naissance_txt = usagerdate
      if usager.ecv_valide
        return
      fields = ["nom", "sexe", "prenoms", "date_naissance",
                "nationalites", "nom_usage", "situation_familiale",
                "ville_naissance", "pays_naissance", "nom_pere",
                "prenom_pere", "nom_mere", "prenom_mere"]
      for field in fields
        if field == "date_naissance"
          origdate = moment($scope.usager_orig.date_naissance).utc().format("DD/MM/YYYY")
          if origdate != usagerdate
            usager.at_least_one_diff = true
            _winden_window()
            break
        else
          if not angular.equals(usager[field], $scope.usager_orig[field])
            usager.at_least_one_diff = true
            _winden_window()
            break

    _winden_window = () ->
      width = window.innerWidth-50
      angular.element(document).find('.modal-dialog').css("width", "#{width}px")


  .directive 'approchantPortailDirective', (SETTINGS) ->
    restrict: 'E'
    templateUrl: 'scripts/xin/recueil_da/modal/approchant_portail.html'
    scope:
      usager: '='
      selectApprochant: '='
      selectApprochantWithoutEC: '='
      usagerOrig: '='
    link: (scope, elem, attrs) ->
      scope.$watch 'usager.at_least_one_diff', (value) ->
        scope.at_least_one_diff = value
        if value
          elem.find('[data-toggle="popover"]').popover()
      scope.api_url = SETTINGS.API_DOMAIN
      # prenoms
      scope.prenoms = ""
      for prenom in scope.usager.prenoms
        scope.prenoms += "#{prenom} "
      scope.prenomsOrig = ""
      for prenom in scope.usagerOrig.prenoms
        scope.prenomsOrig += "#{prenom} "
      # show more
      scope.usager["show_more"] = false
      scope.showMore = ->
        scope.usager.show_more = not scope.usager.show_more


  .directive 'approchantFneDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/recueil_da/modal/approchant_fne.html'
    scope:
      usager: '='
      selectApprochant: '='
      selectApprochantWithoutEC: '='
      usagerOrig: '='
    link: (scope, elem, attrs) ->
      scope.$watch 'usager.at_least_one_diff', (value) ->
        scope.at_least_one_diff = value
        if value
          elem.find('[data-toggle="popover"]').popover()
      # prenoms
      scope.prenoms = ""
      for prenom in scope.usager.prenoms
        scope.prenoms += "#{prenom} "
      scope.prenomsOrig = ""
      for prenom in scope.usagerOrig.prenoms
        scope.prenomsOrig += "#{prenom} "
      # show more
      scope.usager["show_more"] = false
      scope.showMore = ->
        scope.usager.show_more = not scope.usager.show_more
