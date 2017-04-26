'use strict'

breadcrumbsGetSiteDefer = undefined
angular.module('app.views.plage_rdv', ['app.settings', 'ngRoute', 'ui.calendar',
                                       'ui.bootstrap', 'angularMoment',
                                       'xin.listResource', 'xin.tools',
                                       'xin.session', 'xin.backend',
                                       'angular-bootstrap-select',
                                       'app.views.plage_rdv.modal',
                                       'xin.plage_rdv_service'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/plages-rdv',
        templateUrl: 'scripts/views/plage_rdv/show_plage_rdv.html'
        controller: 'ShowPlageRdvController'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetSiteDefer = $q.defer()
          breadcrumbsGetSiteDefer.promise.then (site) ->
            breadcrumbsDefer.resolve([
              ['Plages de rendez-vous']
              [site.libelle, '#/plages-rdv']
            ])
          return breadcrumbsDefer.promise


  .controller 'ShowPlageRdvController', ($scope, $modal,
                                         Backend, BackendWithoutInterceptor, session,
                                         uiCalendarConfig, Calendar) ->

    $scope.calendar = null
    $scope.deleteSelectedCrenDone = {}
    $scope.deletePeriodCrenDone = {}
    $scope.applyDayTemplateDone = {}
    $scope.applyWeekTemplateDone = {}
    ### Find site informations ###
    $scope.site = undefined
    initSite = ->
      $scope.calendar = null
      $scope.site =
        seleted: undefined
        id: undefined
        libelle: undefined
        j_3: true
        actualites: []
    initSite()

    loadSite = (id) ->
      Backend.one('sites', id).get().then(
        (site) ->
          # breadcrums1
          if breadcrumbsGetSiteDefer?
            breadcrumbsGetSiteDefer.resolve(site)
            breadcrumbsGetSiteDefer = undefined

          $scope.site.id = id
          $scope.site.libelle = "#{site.libelle} - #{site.adresse.numero_voie} #{site.adresse.voie}, #{site.adresse.ville} #{site.adresse.code_postal}"
          $scope.site.j_3 = (site.limite_rdv_jrs > 0 and site.limite_rdv_jrs <= 3)
          $scope.calendar = new Calendar(id, "calendar", $scope.editable)

          # Retrieve actualites for this site.
          BackendWithoutInterceptor.one("sites/#{id}/actualites?per_page=100").get().then(
            (result) ->
              $scope.site.actualites = result._items
              for actualite in $scope.site.actualites
                if actualite.type == "ALERTE_GU_RDV_LIMITE_JRS"
                  actualite.creneaux = []
                  for creneau in actualite.contexte.creneaux
                    addCreneauToActualite(actualite, creneau)
            (error) -> throw error
          )
        (error) -> window.location = '#/404'
      )

    # Support Nationale must select specific SITE.
    # We must refresh the calendar with the selected site data.
    $scope.$watch 'site.seleted', (value) ->
      if value? and value != ''
        loadSite(value)
      else
        initSite()

    ### Connected User ###
    $scope.user = null
    $scope.editable = false
    session.getUserPromise().then (user) ->
      $scope.user = user.plain()
      $scope.editable = $scope.user.role != "SUPPORT_NATIONAL"
      if user.site_affecte?.id?
        loadSite(user.site_affecte.id)

    ### Actualités ###
    $scope.actualiteShowed = false
    actualitesLoaded = false

    addCreneauToActualite = (actualite, creneau) ->
      Backend.one(creneau._links.self).get().then(
        (r_creneau) ->
          actualite.creneaux.push(r_creneau)
      )

    $scope.showActualites = ->
      $scope.actualiteShowed = not $scope.actualiteShowed
      if $scope.actualiteShowed
        if not actualitesLoaded
          for actualite in $scope.actualites when actualite.contexte.creneaux?
            for creneau in actualite.contexte.creneaux
              addCreneauToActualite(actualite, creneau)
        actualitesLoaded = true

    $scope.closeActualite = (link) ->
      Backend.one(link).remove().then(
        () ->
          Backend.one('sites/' + actualite.site.id + '/actualites?per_page=100').get().then(
            (result) ->
              $scope.actualites = result._items
              for actualite in $scope.actualites
                if actualite.type == "ALERTE_GU_RDV_3JRS"
                  actualite.creneaux = []
                  for creneau in actualite.contexte.creneaux
                    addCreneauToActualite(actualite, creneau)
            (error) -> throw error
          )
        (error) -> throw error
      )

    $scope.deleteSelectedCren = ->
      if $scope.calendar?
        $scope.calendar.deleteSelectedCren().then(
          () -> $scope.deleteSelectedCrenDone.end()
          (error) ->
            console.log(error)
            $scope.deleteSelectedCrenDone.end()
        )
      else
        $scope.deleteSelectedCrenDone.end()

    $scope.deletePeriodCren = ->
      if $scope.calendar?
        $scope.calendar.deletePeriodCren().then(
          () ->
            $scope.deletePeriodCrenDone.end()
          (error) ->
            console.log("TODO : manage deletePeriodCren error", error)
            $scope.deletePeriodCrenDone.end()
        )
      else
        $scope.deletePeriodCrenDone.end()

    $scope.configureSite = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/plage_rdv/modal/site_settings.html'
        controller: 'ModalInstanceConfigureSiteController'
        resolve:
          siteId: ->
            $scope.site.id
      )
      modalInstance.result.then (limite_rdv_jrs) ->
        $scope.site.j_3 = (limite_rdv_jrs > 0 and limite_rdv_jrs <= 3)

    ### Modeles ###
    $scope.modele =
      libelle: ""
      daySources: []
      weekSources: []

    $scope.configureModeles = (modeleType)->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/plage_rdv/modal/configure_modeles.html'
        controller: 'ModalConfigureModelesController'
        backdrop: false
        keyboard: false
        resolve:
          siteId: ->
            return $scope.site.id
          modeleType: ->
            return modeleType
      )
      modalInstance.result.then (modele) ->
        $scope.modele = modele

    $scope.applyDayTemplate = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/plage_rdv/modal/apply_modeles.html'
        controller: 'ModalApplyModelesController'
        backdrop: false
        keyboard: false
        resolve:
          modele: ->
            return $scope.modele
          siteId: ->
            return $scope.site.id
      )
      modalInstance.result.then(
        (info) ->
          repartition = {}
          for i in [0..6]
            repartition[i] = []
          # Apply dayTemplate foreach selected days
          for source in $scope.modele.daySources
            if info.sunday
              repartition[0].push(source[0])
            if info.monday
              repartition[1].push(source[0])
            if info.tuesday
              repartition[2].push(source[0])
            if info.wednesday
              repartition[3].push(source[0])
            if info.thursday
              repartition[4].push(source[0])
            if info.friday
              repartition[5].push(source[0])
            if info.saturday
              repartition[6].push(source[0])
          $scope.calendar.applyTemplate(info.begin, info.end, repartition).then () ->
            $scope.applyDayTemplateDone.end()
        () -> $scope.applyDayTemplateDone.end()
      )

    $scope.applyWeekTemplate = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/plage_rdv/modal/apply_modeles.html'
        controller: 'ModalApplyModelesController'
        backdrop: false
        keyboard: false
        resolve:
          modele: ->
            return $scope.modele
          siteId: ->
            return $scope.site.id
      )
      modalInstance.result.then(
        (info) ->
          repartition = {}
          for i in [0..6]
            repartition[i] = []
          # Apply weekTemplate
          for source in $scope.modele.weekSources
            day = moment(source[0].start).day()
            repartition[day].push(source[0])
          $scope.calendar.applyTemplate(info.begin, info.end, repartition).then () ->
            $scope.applyWeekTemplateDone.end()
        () -> $scope.applyWeekTemplateDone.end()
      )
