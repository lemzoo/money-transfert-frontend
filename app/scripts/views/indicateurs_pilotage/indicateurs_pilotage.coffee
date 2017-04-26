'use strict'

angular.module('app.views.indicateurs_pilotage', ['ngRoute', 'app.settings',
                                                  'xin.session', 'xin.backend',
                                                  'app.views.indicateurs.creneaux_service',
                                                  'chart.js'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/indicateurs-pilotage',
        templateUrl: 'scripts/views/indicateurs_pilotage/indicateurs_pilotage.html'
        routeAccess: true
        breadcrumbs: "Indicateurs de pilotage"
      .when '/indicateurs-pilotage/charge-spa',
        templateUrl: 'scripts/views/indicateurs_pilotage/show_indicateur.html'
        controller: 'showIndicateursPilotageOldController'
        resolve:
          type: ->
            return "chargeSPA"
        breadcrumbs: [['Indicateurs de pilotage', '#/indicateurs-pilotage'], ['Charge SPA']]
      .when '/indicateurs-pilotage/charge-gu',
        templateUrl: 'scripts/views/indicateurs_pilotage/show_indicateur.html'
        controller: 'showIndicateursPilotageOldController'
        resolve:
          type: ->
            return "chargeGU"
        breadcrumbs: [['Indicateurs de pilotage', '#/indicateurs-pilotage'], ['chargeGU']]
      .when '/indicateurs-pilotage/transferts',
        templateUrl: 'scripts/views/indicateurs_pilotage/show_indicateur.html'
        controller: 'showIndicateursPilotageOldController'
        resolve:
          type: ->
            return "transferts"
        breadcrumbs: [['Indicateurs de pilotage', '#/indicateurs-pilotage'], ['Transferts entre préfectures']]
      .when '/indicateurs-pilotage/prestation-spa',
        templateUrl: 'scripts/views/indicateurs_pilotage/show_indicateur.html'
        controller: 'showIndicateursPilotageOldController'
        resolve:
          type: ->
            return "prestaSPA"
        breadcrumbs: [['Indicateurs de pilotage', '#/indicateurs-pilotage'], ['Qualité prestation SPA']]
      .when '/indicateurs-pilotage/indicateurs',
        templateUrl: 'scripts/views/indicateurs_pilotage/show_indicateurs.html'
        controller: 'showIndicateursPilotageController'
        breadcrumbs: [['Indicateurs de pilotage', '#/indicateurs-pilotage'], ['Indicateurs']]



  .controller 'showIndicateursPilotageOldController', ($scope, session, Backend, type) ->
    $scope.type = type

    ### HTML Variables ###
    $scope.chartSpinner = false
    $scope.csvSpinner = false
    $scope.allowExport = false
    $scope.allowChart = false
    $scope.chartDone = {}
    $scope.csvDone = {}

    ### Filters ###
    user = {}
    # spa selected
    $scope.spa = ""
    # select url for spa
    $scope.spaUrl = ""
    # gu selected
    $scope.gu = ""
    # id of gu list .. OR ...
    guUrl = ""
    # select url for GU
    $scope.guUrl = ""
    # pref selected
    $scope.prefFrom = ""
    $scope.prefTo = ""
    # id of prefs list .. OR ...
    prefUrl = ""
    # select url for pref
    $scope.prefUrl = ""
    session.getUserPromise().then (u) ->
      user = u
      getListArray = (total, value) ->
        return total + " OR #{value.id}"
      Backend.one("sites/#{user.site_affecte.id}").get().then(
        (prefs) ->
          # get all GU for user prefectures
          prefUrl = prefs.prefectures.slice(1).reduce(getListArray, prefs.prefectures[0].id)
          $scope.prefUrl = "sites?fq=id:(#{prefUrl})"
          $scope.guUrl = "sites?fq=autorite_rattachement_r:(#{prefUrl})"

          if type in ["chargeSPA", "prestaSPA", "chargeGU"]
            Backend.all("sites?fq=autorite_rattachement_r:(#{prefUrl})").getList().then(
              (gus) ->
                guUrl = gus.slice(1).reduce(getListArray, gus[0].id)
                $scope.spaUrl = "sites?fq=guichets_uniques_rs:(#{guUrl})"
              (error) -> console.log(error)
            )

        (error) -> console.log(error)
      )

    ### Watch Variables ###
    $scope.begin = ''
    $scope.end = ''

    ### error Variables ###
    $scope.errorBegin = null
    $scope.errorEnd = null

    ### CSV String ###
    csvContent = ""

    ### Chart parameters ###
    $scope.labels = ['JANVIER', 'FÉVRIER', 'MARS', 'AVRIL', 'MAI', 'JUIN', 'JUILLET', 'AOÛT', 'SEPTEMBRE', 'OCTOBRE', 'NOVEMBRE', 'DÉCEMBRE']
    $scope.data = []
    $scope.series = null
    view = null # if month/week/day
    requestCount = 0

    ### Watch begin and end dates ###
    $scope.$watch 'begin', (value) ->
      checkDates()
    , true

    $scope.$watch 'end', (value) ->
      checkDates()
    , true

    checkDates = () ->
      allowChart = true
      if not $scope.begin? or $scope.begin == ""
        allowChart = false
        $scope.errorBegin = 'Veuillez sélectionner une date'
      else if $scope.begin == "Invalid date"
        allowChart = false
      if not $scope.end? or $scope.end == ""
        allowChart = false
        $scope.errorEnd = 'Veuillez sélectionner une date'
      else if $scope.end == "Invalid date"
        allowChart = false
      if allowChart
        begin = moment($scope.begin)
        end = moment($scope.end)
        if begin.isAfter(end)
          $scope.errorEnd = "La date de fin doit être postérieur à la date de début"
          allowChart = false
        else
          $scope.errorEnd = null
      $scope.allowChart = allowChart


    ### Load Informations ans Update Chart Datas ###
    $scope.load = ->
      $scope.allowExport = false
      $scope.chartSpinner = true
      # Init Data Value
      $scope.series = [moment($scope.begin).year()..moment($scope.end).year()]
      $scope.data = []
      for i in [1..$scope.series.length]
        $scope.data.push([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
      if (type == 'chargeSPA')
        retrieveChargeSPA()
      else if (type == 'chargeGU')
        retrieveChargeGU()
      else if (type == 'prestaSPA')
        retrievePrestaSPA()
      else if (type == 'transferts')
        retrieveTranferts()
      else
        $scope.chartSpinner = false
        $scope.chartDone.end?()


    ### Nombre de recueils enregistrés depuis les Plateformes de Premier Accueil ###
    retrieveChargeSPA = ->
      requestCount = 0
      # Cut Months
      tmpBegin = moment($scope.begin)
      end = moment($scope.end)
      while tmpBegin.isBefore(end) or tmpBegin.isSame(end)
        requestCount++
        tmpEnd = null
        test = moment(tmpBegin)
        if test.endOf('month').isBefore(end)
          tmpEnd = test.endOf('month')
        else
          tmpEnd = end
        retrieveChargeSPABackend(tmpBegin, tmpEnd)
        tmpBegin.endOf('month').add(1, 'day')

    # Backend call
    retrieveChargeSPABackend = (begin, end) ->
      url = "recueils_da?fq=structure_guichet_unique:(#{guUrl})"
      saveBegin = angular.copy(begin)
      fqSite = ""
      if not $scope.spa? or $scope.spa == ""
        fqSite = "&fq=-(structure_accueil:(#{guUrl}))"
      else
        fqSite = "&fq=structure_accueil:#{$scope.spa}"
      fqCreated = "&fq=_created:[#{begin.format('YYYY-MM-DD[T]00:00:00[Z]')} TO #{end.format('YYYY-MM-DD[T]23:59:59[Z]')}]"
      Backend.all(url+fqSite+fqCreated).getList().then(
        (recueils_das) ->
          requestCount--
          $scope.data[$scope.series.indexOf(saveBegin.year())][saveBegin.month()] = recueils_das._meta.total
          if requestCount == 0
            $scope.chartSpinner = false
            $scope.allowExport = true
            $scope.chartDone.end?()
        (error) ->
          console.log(error)
          $scope.chartSpinner = false
          $scope.chartDone.end?()
      )


    ### Nombre de rendez-vous réalisés en GU ###
    retrieveChargeGU = ->
      requestCount = 0
      # Cut Months
      tmpBegin = moment($scope.begin)
      end = moment($scope.end)
      while tmpBegin.isBefore(end) or tmpBegin.isSame(end)
        requestCount++
        tmpEnd = null
        test = moment(tmpBegin)
        if test.endOf('month').isBefore(end)
          tmpEnd = test.endOf('month')
        else
          tmpEnd = end
        retrieveChargeGUBackend(tmpBegin, tmpEnd)
        tmpBegin.endOf('month').add(1, 'day')

    # Backend call
    retrieveChargeGUBackend = (begin, end) ->
      url = ""
      saveBegin = angular.copy(begin)
      fqSite = ""
      if not $scope.gu? or $scope.spa == ""
        url = "recueils_da?fq=structure_guichet_unique:#{guUrl}"
      else
        url = "recueils_da?fq=structure_guichet_unique:#{$scope.gu}"
      fqRdv = "&fq=rendez_vous_gu_date_dt:[#{begin.format('YYYY-MM-DD[T]00:00:00[Z]')} TO #{end.format('YYYY-MM-DD[T]23:59:59[Z]')}]"
      Backend.all(url+fqRdv).getList().then(
        (recueils_das) ->
          requestCount--
          $scope.data[$scope.series.indexOf(saveBegin.year())][saveBegin.month()] = recueils_das._meta.total
          if requestCount == 0
            $scope.chartSpinner = false
            $scope.allowExport = true
            $scope.chartDone.end?()
        (error) ->
          console.log(error)
          $scope.chartSpinner = false
          $scope.chartDone.end?()
      )


    # Nombre d’erreurs de saisies des SPA
    retrievePrestaSPA = ->
      if not $scope.spa? or $scope.spa == ""
        $scope.chartSpinner = false
        $scope.chartDone.end?()
        return
      url = "analytics/corrections_pa_realise"
      end = moment($scope.end).format('YYYY-MM-DD[T]23:59:59[Z]')
      fqSpa = "structure_accueil=#{$scope.spa}"

      Backend.one("#{url}?debut=#{$scope.begin}&fin=#{end}&#{fqSpa}").get().then(
        (elts) ->
          for elt in elts._items or []
            date = moment(elt.date)
            year = $scope.series.indexOf(date.year())
            month = date.month()
            $scope.data[year][month]++
          $scope.chartSpinner = false
          $scope.allowExport = true
          $scope.chartDone.end?()
        (error) ->
          console.log(error)
          $scope.chartSpinner = false
          $scope.chartDone.end?()
      )


    # Flux de transferts entre préfectures
    retrieveTranferts = ->
      url = "analytics/transferts_prefecture"
      end = moment($scope.end).format('YYYY-MM-DD[T]23:59:59[Z]')
      fqPref = ""
      if $scope.prefFrom? and $scope.prefFrom != ""
        fqPref += "&origine=#{$scope.prefFrom}"
      if $scope.prefTo? and $scope.prefTo != ""
        fqPref += "&destination=#{$scope.prefTo}"
      Backend.one("#{url}?debut=#{$scope.begin}&fin=#{end}#{fqPref}").get().then(
        (elts) ->
          for elt in elts._items or []
            date = moment(elt.date)
            year = $scope.series.indexOf(date.year())
            month = date.month()
            $scope.data[year][month]++
          $scope.chartSpinner = false
          $scope.allowExport = true
          $scope.chartDone.end?()
        (error) ->
          console.log(error)
          $scope.chartSpinner = false
          $scope.chartDone.end?()
      )


    ### Init Chart Data format ###
    $scope.initDataFormat = ->
      console.log("initDataFormat")


    ### Generate CSV String ###
    $scope.generateCSVString = ->
      itemDelimiter = ';'
      lineDelimiter = '\n'

      # Init
      csvContent = '""'
      for serie in $scope.series
        csvContent += itemDelimiter + '"' + serie + '"'
      csvContent += lineDelimiter

      # Content
      for i in [0 ... $scope.labels.length]
        csvContent += '"' + $scope.labels[i] + '"'
        for j in [0 ... $scope.series.length]
          csvContent += itemDelimiter + $scope.data[j][i]
        csvContent += lineDelimiter


    ### Create file ###
    $scope.createCSV = () ->
      $scope.spinner = true
      $scope.generateCSVString()
      # Generate CSV file
      anchor = angular.element('<a></a>')
      anchor.css({display: 'none'})
      angular.element(document.body).append(anchor)
      anchor.attr({
        href: 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvContent),
        target: '_blank',
        download: 'export_' + type + '.csv'
      })[0].click()
      anchor.remove()
      $scope.spinner = false
      $scope.csvDone.end?()



  .controller 'showIndicateursPilotageController', ($scope, $q, session, Backend,
                                                    get_creneaux_ouverts) ->
    ### HTML Variables ###
    $scope.chartSpinner = false
    $scope.csvSpinner = false
    $scope.allowExport = false
    $scope.allowChart = false
    $scope.chartDone = {}

    # Array rows
    $scope.prefs = []
    $scope.gus = []
    $scope.spas = []
    $scope.rdv_spa_gu = {}
    initArrays = ->
      $scope.rdv_spa_gu = {}

      $scope.total_prefs =
        procedure_normale: 0
        procedure_acceleree: 0
        procedure_dublin: 0
        en_renouvellement: 0
      $scope.total_gus =
        creneaux_ouverts: 0
        creneaux_rdv: 0
        creneaux_honores: 0
        procedure_normale: 0
        procedure_acceleree: 0
        procedure_dublin: 0
        echec_prise_empreinte: 0

      for pref in $scope.prefs
        pref.procedure_normale = 0
        pref.procedure_acceleree = 0
        pref.procedure_dublin = 0
        pref.en_renouvellement = 0
      for gu in $scope.gus
        gu.creneaux_ouverts = 0
        gu.creneaux_rdv = 0
        gu.creneaux_honores = 0
        gu.delai_rdv = 0
        gu.procedure_normale = 0
        gu.procedure_acceleree = 0
        gu.procedure_dublin = 0
        gu.echec_prise_empreinte = 0
      for spa in $scope.spas
        spa.capacite_min = 0
        spa.capacite_max = 0
    initArrays()

    $scope.user = {}
    solrPref = ""
    solrGu = ""
    session.getUserPromise().then (u) ->
      $scope.user = u
      getListArray = (total, value) ->
        return total + " OR #{value.id}"
      if u.role in ["RESPONSABLE_NATIONAL", "GESTIONNAIRE_NATIONAL"]
        getSites("sites")
      else if u.role == 'GESTIONNAIRE_ASILE_PREFECTURE'
        getSite(u.site_rattache._links.self)
      else if u.role in ["RESPONSABLE_GU_ASILE_PREFECTURE", "RESPONSABLE_GU_DT_OFII"]
        getSite(u.site_rattache._links.self)
        solrPref = u.site_rattache.id
        Backend.all("sites?fq=autorite_rattachement_r:(#{solrPref})").getList().then(
          (gus) ->
            for site in gus
              getSite(site._links.self)
            solrGu = gus.slice(1).reduce(getListArray, gus[0].id)
            # Get all SPA
            Backend.all("sites?fq=guichets_uniques_rs:(#{solrGu})").getList().then(
              (spas) ->
                for site in spas
                  getSite(site._links.self)
              (error) -> console.log(error)
            )
          (error) -> console.log(error)
        )
      else if u.role == "RESPONSABLE_ZONAL"
        Backend.one("sites/#{$scope.user.site_affecte.id}").get().then(
          (zone) ->
            # get all Pref
            for site in zone.prefectures
              getSite(site._links.self)
            # get all GU for user prefectures
            solrPref = zone.prefectures.slice(1).reduce(getListArray, zone.prefectures[0].id)
            Backend.all("sites?fq=autorite_rattachement_r:(#{solrPref})").getList().then(
              (gus) ->
                for site in gus
                  getSite(site._links.self)
                solrGu = gus.slice(1).reduce(getListArray, gus[0].id)
                # $scope.spaUrl = "sites?fq=guichets_uniques_rs:(#{guUrl})"
                # Get all SPA
                Backend.all("sites?fq=guichets_uniques_rs:(#{solrGu})").getList().then(
                  (spas) ->
                    for site in spas
                      getSite(site._links.self)
                  (error) -> console.log(error)
                )
              (error) -> console.log(error)
            )
          (error) -> console.log(error)
        )

    sortByLibelle = (a, b) ->
      return a.libelle.localeCompare(b.libelle)

    getSites = (link) ->
      Backend.all(link).getList().then(
        (sites) ->
          for site in sites
            processSite(site)
          if sites._links.next?
            getSites(sites._links.next)
        (error) -> console.log(error)
      )

    getSite = (link) ->
      Backend.one(link).get().then(
        (site) -> processSite(site)
        (error) -> console.log(error)
      )

    processSite = (site) ->
      if site.type == "Prefecture"
        $scope.prefs.push(
          libelle: site.libelle
          id: site.id
          procedure_normale: 0
          procedure_acceleree: 0
          procedure_dublin: 0
          en_renouvellement: 0
        )
        $scope.prefs.sort(sortByLibelle)
      else if site.type == "GU"
        $scope.gus.push(
          libelle: site.libelle
          id: site.id
          creneaux_ouverts: 0
          creneaux_rdv: 0
          creneaux_honores: 0
          delai_rdv: 0
          procedure_normale: 0
          procedure_acceleree: 0
          procedure_dublin: 0
          echec_prise_empreinte: 0
        )
        $scope.gus.sort(sortByLibelle)
      else if site.type == "StructureAccueil"
        $scope.spas.push(
          libelle: site.libelle
          id: site.id
          capacite_min: 0
          capacite_max: 0
          gu_dpt: site.guichets_uniques[0].id
        )
        $scope.spas.sort(sortByLibelle)

    ### Watch Variables ###
    $scope.date_errors = []
    $scope.month = null
    $scope.year = null
    begin = null
    end = null
    nb_site_by_request = 5

    ### Watch begin and end dates ###
    $scope.$watch 'month', (value) ->
      checkDates()
    , true

    $scope.$watch 'year', (value) ->
      checkDates()
    , true

    checkDates = () ->
      $scope.date_errors = []
      allowChart = true
      if not $scope.month?
        allowChart = false
        $scope.date_errors.push('Veuillez sélectionner un mois')
      if not $scope.year? or $scope.year == "" or $scope.year.length != 4
        allowChart = false
        $scope.date_errors.push('Veuillez inscrire une année au format AAAA')
      if allowChart
        if isNaN(parseInt($scope.year))
          allowChart = false
          $scope.date_errors.push("Date invalide")
        begin = moment("#{$scope.year}-#{$scope.month}-01 00:00:00")
        end = moment(begin).endOf("month").format('YYYY-MM-DD[T]23:59:59[Z]')
        begin = begin.format('YYYY-MM-DD[T]00:00:00[Z]')
      $scope.allowChart = allowChart

    $scope.collapse = (tab) ->
      if not $scope[tab]?
        $scope[tab] = false
      $scope[tab] = !$scope[tab]

    ### Load Informations and Update Chart Datas ###
    waitingCollections = []
    $scope.loadOnlyActivityAsile = ->
      $scope.allowExport = false
      $scope.chartSpinner = true
      initArrays()
      date = "[#{begin} TO #{end}]"
      waitingCollections =
        renouvellement: 0
      # pref
      # renouvellement
      loadActivityAsile(date)

    $scope.load = ->
      $scope.allowExport = false
      $scope.chartSpinner = true
      initArrays()
      date = "[#{begin} TO #{end}]"
      waitingCollections =
        creneaux_ouverts: 0
        creneaux_rdv: 0
        creneaux_honores: 0
        delai_rdv: 0
        premiere_attestation: 0
        echec_prise_empreinte: 0
        rdv: 0
        renouvellement: 0
        capacite: 0
      # GU
      # statistiques Guichet Unique
      loadStatsGU(date)
      # SPA GU
      # nombre de rendez-vous pris par chaque SPA pour un GU
      loadRDV(date)
      # pref
      # renouvellement
      loadActivityAsile(date)
      # spa
      # capacité journalière
      loadCapacity(date)

    makeQuery = (url, resource, field_name = "") ->
      Backend.one(url).get().then(
        (response) ->
          response_parse = JSON.parse(response)
          if resource in ["creneaux_ouverts", "creneaux_rdv", "creneaux_honores", "echec_prise_empreinte"]
            parseResponse(response_parse, field_name)

          else if resource == "delai_rdv"
            for key, group of response_parse.grouped
              id = key.split(":")[1]
              n = 0
              somme = 0
              for doc in group.doclist.docs
                n += 1
                somme += doc.delai_i
              moyenne = 0
              if n
                moyenne = somme/n
              for gu, index in $scope.gus
                if gu.id == id
                  $scope.gus[index]["delai_rdv"] = moyenne
                  break

          else if resource == "premiere_attestation"
            for facet in response_parse.facets.facet_pivot["guichet_unique_s,procedure_type_s"]
              id = facet.value
              for gu, index in $scope.gus
                if gu.id == id
                  for sub_facet in facet.pivot
                    if sub_facet.value == "NORMALE"
                      $scope.gus[index]["procedure_normale"] = sub_facet.count
                      $scope.total_gus["procedure_normale"] += sub_facet.count
                    else if sub_facet.value == "ACCELEREE"
                      $scope.gus[index]["procedure_acceleree"] = sub_facet.count
                      $scope.total_gus["procedure_acceleree"] += sub_facet.count
                    else if sub_facet.value == "DUBLIN"
                      $scope.gus[index]["procedure_dublin"] = sub_facet.count
                      $scope.total_gus["procedure_dublin"] += sub_facet.count
                  break

          else if resource == "renouvellement"
            for facet in response_parse.facets.facet_pivot["prefecture_s,renouvellement_i,procedure_type_s"]
              id = facet.value
              for site, index in $scope.prefs
                if site.id == id
                  for sub_facet in facet.pivot # renouvellement
                    renouvellement_i = sub_facet.value
                    if renouvellement_i == 1
                      for sub_sub_facet in sub_facet.pivot # procedure type
                        if sub_sub_facet.value == "NORMALE"
                          $scope.prefs[index]["procedure_normale"] = sub_sub_facet.count
                          $scope.total_prefs["procedure_normale"] += sub_sub_facet.count
                        else if sub_sub_facet.value == "ACCELEREE"
                          $scope.prefs[index]["procedure_acceleree"] = sub_sub_facet.count
                          $scope.total_prefs["procedure_acceleree"] += sub_sub_facet.count
                        else if sub_sub_facet.value == "DUBLIN"
                          $scope.prefs[index]["procedure_dublin"] = sub_sub_facet.count
                          $scope.total_prefs["procedure_dublin"] += sub_sub_facet.count
                    else if renouvellement_i >= 2
                      $scope.prefs[index]["en_renouvellement"] = sub_facet.count
                      $scope.total_prefs["en_renouvellement"] += sub_facet.count
                  break

          else
            console.log("error : #{resource}")
          endLoad(resource)
        (error) ->
          console.log(error)
          endLoad(resource)
      )


    parseResponse = (response_parse, field) ->
      for key, group of response_parse.grouped
        key = key.split(":")
        type_site = key[0]
        id = key[1]
        if type_site == "guichet_unique_s"
          for gu, index in $scope.gus
            if gu.id == id
              $scope.gus[index][field] = group.doclist.numFound
              $scope.total_gus[field] += group.doclist.numFound
              break
        else
          console.log("type_site", type_site)


    loadStatsGU = (date) ->
      # rdv ouverts
      get_creneaux_ouverts($scope.gus, date).then (results) ->
        for guQueried, iQueried of results
          for gu, index in $scope.gus
            if gu.id == guQueried
              $scope.gus[index]["creneaux_ouverts"] = iQueried
              $scope.total_gus["creneaux_ouverts"] += iQueried
              break

      group_query = "group=true"
      facet_query = "facet=true"
      site_filter = ""

      makeRequests = ->
        # rdv pris
        waitingCollections.creneaux_rdv += 1
        url = "analytics?fq=doc_type:rendez_vous_pris_spa&fq=date_creneau_dt:#{date}&#{group_query}"
        makeQuery(url, "creneaux_rdv", "creneaux_rdv")
        # rdv honorés
        waitingCollections.creneaux_honores += 1
        url = "analytics?fq=doc_type:rendez_vous_honore&fq=date_creneau_dt:#{date}&#{group_query}"
        makeQuery(url, "creneaux_honores", "creneaux_honores")
        # délai rdv
        waitingCollections.delai_rdv += 1
        url = "analytics?fq=doc_type:rendez_vous_pris_spa&fq=date_pris_dt:#{date}&#{group_query}&group.limit=1000"
        makeQuery(url, "delai_rdv")
        # attestations délivrées
        waitingCollections.premiere_attestation += 1
        url = "analytics?fq=doc_type:droit_cree&fq=date_dt:#{date}"
        url += "&fq=renouvellement_i:0"
        if site_filter != ""
          url += "&fq=guichet_unique_s:(#{site_filter})"
        url += "&#{facet_query}&facet.pivot=guichet_unique_s,procedure_type_s"
        makeQuery(url, "premiere_attestation")
        # refus prise d'empreintes
        waitingCollections.echec_prise_empreinte += 1
        url = "analytics?fq=doc_type:rendez_vous_annule&fq=date_creneau_dt:#{date}&#{group_query}"
        url += "&fq=motif_s:ECHEC_PRISE_EMPREINTES"
        makeQuery(url, "echec_prise_empreinte", "echec_prise_empreinte")

      index = 0
      while index < $scope.gus.length
        group_query += "&group.query=guichet_unique_s:#{$scope.gus[index].id}"
        if site_filter != ""
          site_filter += " OR #{$scope.gus[index].id}"
        else
          site_filter += "#{$scope.gus[index].id}"
        index = index + 1
        if index % nb_site_by_request is 0
          makeRequests()
          group_query = "group=true"
          site_filter = ""

      if index % nb_site_by_request isnt 0
        makeRequests()


    loadRDV = (date) ->
      facet_query = "facet=true&facet.pivot=site_pa_s,guichet_unique_s"
      site_filter = ""

      makeRequests = ->
        waitingCollections.rdv += 1
        url = "analytics?fq=doc_type:rendez_vous_pris_spa&fq=date_creneau_dt:#{date}"
        if site_filter != ""
          url += "&fq=site_pa_s:(#{site_filter})"
        url += "&#{facet_query}"

        Backend.one(url).get().then(
          (response) ->
            response_parse = JSON.parse(response)
            gus = []
            for gu in $scope.gus or []
              gus.push(gu.id)
            for facet in response_parse.facets.facet_pivot['site_pa_s,guichet_unique_s']
              # Get all RDV
              for spa in $scope.spas
                if spa.id is facet.value
                  # init $scope.rdv_spa_gu[spa.id]
                  if not $scope.rdv_spa_gu[spa.id]?
                    $scope.rdv_spa_gu[spa.id] = {
                      "total": 0
                      "total_hdpt": 0
                      "percent_hdpt": 0
                    }
                  # Get all rdv (specific SPA)
                  for sub_facet in facet.pivot # guichet_unique_s
                    gu_id = sub_facet.value
                    if gu_id in gus
                      $scope.rdv_spa_gu[spa.id]["total"] += sub_facet.count
                      # init $scope.rdv_spa_gu[gu.id]
                      if not $scope.rdv_spa_gu[gu_id]?
                        $scope.rdv_spa_gu[gu_id] = {
                          "total": 0
                          "total_hdpt": 0
                          "percent_hdpt": 0
                        }
                      # gu informations
                      $scope.rdv_spa_gu[gu_id][spa.id] = sub_facet.count
                      $scope.rdv_spa_gu[gu_id]["total"] += sub_facet.count
                      # informations about hdpt
                      if spa.gu_dpt isnt gu_id
                        $scope.rdv_spa_gu[spa.id]["total_hdpt"] += sub_facet.count
                        $scope.rdv_spa_gu[gu_id]["total_hdpt"] += sub_facet.count
                    if $scope.rdv_spa_gu[gu_id]? && $scope.rdv_spa_gu[gu_id]["total"] != 0
                      $scope.rdv_spa_gu[gu_id]["percent_hdpt"] = $scope.rdv_spa_gu[gu_id]["total_hdpt"] * 100 / $scope.rdv_spa_gu[gu_id]["total"]
                  if $scope.rdv_spa_gu[spa.id]? and $scope.rdv_spa_gu[spa.id]["total"] != 0
                    $scope.rdv_spa_gu[spa.id]["percent_hdpt"] = $scope.rdv_spa_gu[spa.id]["total_hdpt"] * 100 / $scope.rdv_spa_gu[spa.id]["total"]
                  break
            endLoad("rdv")
          (error) ->
            console.log(error)
            endLoad("rdv")
        )

      index = 0
      while index < $scope.spas.length
        if site_filter != ""
          site_filter += " OR #{$scope.spas[index].id}"
        else
          site_filter += "#{$scope.spas[index].id}"
        index = index + 1
        if index % nb_site_by_request is 0
          makeRequests()
          site_filter = ""

      if index % nb_site_by_request isnt 0
        makeRequests()


    loadActivityAsile = (date) ->
      facet_query = "facet=true"
      site_filter = ""

      makeRequests = ->
        waitingCollections.renouvellement += 1
        url = "analytics?fq=doc_type:droit_cree&fq=date_dt:#{date}"
        url += "&fq=renouvellement_i:(1 OR 2)"
        if site_filter != ""
          url += "&fq=prefecture_s:(#{site_filter})"
        url += "&#{facet_query}&facet.pivot=prefecture_s,renouvellement_i,procedure_type_s"
        makeQuery(url, "renouvellement")

      index = 0
      while index < $scope.prefs.length
        if site_filter != ""
          site_filter += " OR #{$scope.prefs[index].id}"
        else
          site_filter += "#{$scope.prefs[index].id}"
        index = index + 1
        if index % nb_site_by_request is 0
          makeRequests()
          site_filter = ""

      if index % nb_site_by_request isnt 0
        makeRequests()


    loadCapacity = (date) ->
      facet_query = "facet=true"
      site_filter = ""

      makeRequests = ->
        waitingCollections.capacite += 1
        url = "analytics?fq=doc_type:on_pa_realise&fq=date_dt:#{date}"
        if site_filter != ""
          url += "&fq=site_pa_s:(#{site_filter})"
        url += "&#{facet_query}"
        url += "&facet.pivot=site_pa_s,date_dt,personnes_i"

        Backend.one(url).get().then(
          (response) ->
            response_parse = JSON.parse(response)
            for facet in response_parse.facets.facet_pivot['site_pa_s,date_dt,personnes_i']
              # Get all capacities
              for spa in $scope.spas
                if spa.id is facet.value
                  # init capacity foreach day
                  capacities = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
                  # Get all capacities (specific SPA)
                  for sub_facet in facet.pivot # date_dt
                    date_dt = moment(sub_facet.value)
                    for sub_sub_facet in sub_facet.pivot # personnes_i
                      personnes_i = sub_sub_facet.value
                      position = date_dt.day()
                      capacities[position] = capacities[position] + personnes_i
                  # Find min/max capacities
                  for capacity in capacities
                    if capacity isnt 0
                      if spa.capacite_min is 0
                        spa.capacite_min = capacity
                      else
                        spa.capacite_min = Math.min(spa.capacite_min, capacity)
                      if spa.capacite_max is 0
                        spa.capacite_max = capacity
                      else
                        spa.capacite_max = Math.max(spa.capacite_max, capacity)
                  break
            endLoad("capacite")
          (error) ->
            console.log(error)
            endLoad("capacite")
        )

      index = 0
      while index < $scope.spas.length
        if site_filter != ""
          site_filter += " OR #{$scope.spas[index].id}"
        else
          site_filter += "#{$scope.spas[index].id}"
        index = index + 1
        if index % nb_site_by_request is 0
          makeRequests()
          site_filter = ""

      if index % nb_site_by_request isnt 0
        makeRequests()


    endLoad = (collection) ->
      waitingCollections[collection] -= 1
      for key of waitingCollections
        if waitingCollections[key]? && waitingCollections[key] != 0
          return
      $scope.chartSpinner = false
      $scope.chartDone.end?()
      $scope.allowExport = true


    ### CSV String ###
    csvContent = ""
    ### Generate CSV String ###
    $scope.generateCSVString = (type) ->
      itemDelimiter = ';'
      lineDelimiter = '\n'

      # Init
      csvContent = ""
      if type == "GU"
        csvContent += '""' + itemDelimiter
        csvContent += '"Nombre de rendez-vous ouverts par le GUDA"' + itemDelimiter
        csvContent += '"Nombre de créneaux de rendez-vous ayant été attribué suite à une prise de rendez-vous"' + itemDelimiter
        csvContent += '"Nombre de créneaux de rendez-vous attribué ayant donné lieu à un rendez-vous honoré"' + itemDelimiter
        csvContent += '"Délai de rendez-vous au guichet unique (moyenne mensuelle en jours)"' + itemDelimiter
        csvContent += '"Nombre d\'attestations de demande d\'asile délivrées, Procédure normale"' + itemDelimiter
        csvContent += '"Nombre d\'attestations de demande d\'asile délivrées, Procédure accélérée"' + itemDelimiter
        csvContent += '"Nombre d\'attestations de demande d\'asile délivrées, Procédure Dublin"' + itemDelimiter
        csvContent += '"Nombre de refus de prise d\'empreintes ou inexploitables"' + lineDelimiter
        for gu in $scope.gus
          csvContent += "\"#{gu.libelle}\"" + itemDelimiter
          csvContent += "\"#{gu.creneaux_ouverts}\"" + itemDelimiter
          csvContent += "\"#{gu.creneaux_rdv}\"" + itemDelimiter
          csvContent += "\"#{gu.creneaux_honores}\"" + itemDelimiter
          csvContent += "\"#{gu.delai_rdv}\"" + itemDelimiter
          csvContent += "\"#{gu.procedure_normale}\"" + itemDelimiter
          csvContent += "\"#{gu.procedure_acceleree}\"" + itemDelimiter
          csvContent += "\"#{gu.procedure_dublin}\"" + itemDelimiter
          csvContent += "\"#{gu.echec_prise_empreinte}\"" + lineDelimiter
        csvContent += "\"Total\"" + itemDelimiter
        csvContent += "\"#{$scope.total_gus.creneaux_ouverts}\"" + itemDelimiter
        csvContent += "\"#{$scope.total_gus.creneaux_rdv}\"" + itemDelimiter
        csvContent += "\"#{$scope.total_gus.creneaux_honores}\"" + itemDelimiter
        csvContent += "\"N/A\"" + itemDelimiter
        csvContent += "\"#{$scope.total_gus.procedure_normale}\"" + itemDelimiter
        csvContent += "\"#{$scope.total_gus.procedure_acceleree}\"" + itemDelimiter
        csvContent += "\"#{$scope.total_gus.procedure_dublin}\"" + itemDelimiter
        csvContent += "\"#{$scope.total_gus.echec_prise_empreinte}\"" + lineDelimiter

      else if type == "PREF"
        csvContent += '""' + itemDelimiter
        csvContent += '"Nombre d\'attestations de premier renouvellement, procédure normale (9 mois)"' + itemDelimiter
        csvContent += '"Nombre d\'attestations de premier renouvellement, procédure accélérée (6 mois)"' + itemDelimiter
        csvContent += '"Nombre d\'attestations de premier renouvellement, procédure dublin (4 mois)"' + itemDelimiter
        csvContent += '"Nombre d\'attestations de renouvellement ultérieur au premier renouvellement"' + lineDelimiter
        for pref in $scope.prefs
          csvContent += "\"#{pref.libelle}\"" + itemDelimiter
          csvContent += "\"#{pref.procedure_normale}\"" + itemDelimiter
          csvContent += "\"#{pref.procedure_acceleree}\"" + itemDelimiter
          csvContent += "\"#{pref.procedure_dublin}\"" + itemDelimiter
          csvContent += "\"#{pref.en_renouvellement}\"" + lineDelimiter
        csvContent += "\"Total\"" + itemDelimiter
        csvContent += "\"#{$scope.total_prefs.procedure_normale}\"" + itemDelimiter
        csvContent += "\"#{$scope.total_prefs.procedure_acceleree}\"" + itemDelimiter
        csvContent += "\"#{$scope.total_prefs.procedure_dublin}\"" + itemDelimiter
        csvContent += "\"#{$scope.total_prefs.en_renouvellement}\"" + lineDelimiter

      else if type == "SPA"
        csvContent += '""' + itemDelimiter
        csvContent += '"Capacité journalière d\'accueil constatée en première demande d\'asile constatée, mini"' + itemDelimiter
        csvContent += '"Capacité journalière d\'accueil constatée en première demande d\'asile constatée, maxi"' + lineDelimiter
        for site in $scope.spas
          csvContent += "\"#{site.libelle}\"" + itemDelimiter
          csvContent += "\"#{site.capacite_min}\"" + itemDelimiter
          csvContent += "\"#{site.capacite_max}\"" + lineDelimiter

      else if type == "RDV_SPA_GU"
        csvContent += '"GU \ SPA"' + itemDelimiter
        for spa in $scope.spas
          csvContent += "\"#{spa.libelle}\"" + itemDelimiter
        csvContent += '"Total RDV"' + itemDelimiter
        csvContent += '"Total RDV reçus hors département"' + itemDelimiter
        csvContent += '"% RDV reçus hors département"' + lineDelimiter

        for site in $scope.gus
          csvContent += "\"#{site.libelle}\"" + itemDelimiter
          if $scope.rdv_spa_gu[site.id]?
            for spa in $scope.spas
              csvContent += if $scope.rdv_spa_gu[site.id][spa.id]? then "\"#{$scope.rdv_spa_gu[site.id][spa.id]}\"" else "0"
              csvContent += itemDelimiter
            csvContent += "\"#{$scope.rdv_spa_gu[site.id].total}\"" + itemDelimiter
            csvContent += "\"#{$scope.rdv_spa_gu[site.id].total_hdpt}\"" + itemDelimiter
            csvContent += "\"#{$scope.rdv_spa_gu[site.id].percent_hdpt}\"" + lineDelimiter
          else
            for spa in $scope.spas
              csvContent += "0" + itemDelimiter
            csvContent += "0" + itemDelimiter + "0" + itemDelimiter + "0" + lineDelimiter

        csvContent += '"Total RDV"' + itemDelimiter
        for site in $scope.spas
          csvContent += if $scope.rdv_spa_gu[site.id]? then "\"#{$scope.rdv_spa_gu[site.id].total}\"" else "0"
          csvContent += itemDelimiter
        csvContent += itemDelimiter + itemDelimiter + lineDelimiter

        csvContent += '"Total RDV fixés hors département par SPA"' + itemDelimiter
        for site in $scope.spas
          csvContent += if $scope.rdv_spa_gu[site.id]? then "\"#{$scope.rdv_spa_gu[site.id].total_hdpt}\"" else "0"
          csvContent += itemDelimiter
        csvContent += itemDelimiter + itemDelimiter + lineDelimiter

        csvContent += '"Total RDV hors département par SPA"' + itemDelimiter
        for site in $scope.spas
          csvContent += if $scope.rdv_spa_gu[site.id]? then "\"#{$scope.rdv_spa_gu[site.id].percent_hdpt}\"" else "0"
          csvContent += itemDelimiter
        csvContent += itemDelimiter + itemDelimiter + lineDelimiter

      return csvContent

    ### Create file ###
    $scope.createCSV = (type) ->
      $scope.spinner = true
      $scope.generateCSVString(type)
      # Generate CSV file
      anchor = angular.element('<a></a>')
      anchor.css({display: 'none'})
      angular.element(document.body).append(anchor)
      anchor.attr(
        href: 'data:text/csv;charset=utf-8,%EF%BB%BF' + encodeURIComponent(csvContent)
        target: '_blank'
        download: 'export_indicateurs_pp.csv'
      )[0].click()
      anchor.remove()
      $scope.spinner = false
