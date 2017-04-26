'use strict'

angular
  .module('app', [
    'ngAnimate'
    'ngRoute'
    'flow'
    'app.settings'
    'app.navigationbar_config'
    'xin.sessionWaiter'
    'xin.testBackendConnexion'
    'xin.login'
    'xin.tools'
    'xin.session'
    'xin.backend'
    'xin.routeAccess'
    'xin.modal'
    'xin.habilitations.modal'
    'app.views.accueil'
    'app.views.utilisateur'
    'app.views.site'
    'app.views.webhook'
    'app.views.webhook_rabbit'
    'app.views.plage_rdv'
    'app.views.premier_accueil'
    'app.views.gu_enregistrement'
    'app.views.attestation'
    'app.views.da'
    'app.views.parametrage'
    'app.views.usager'
    'app.views.transfert'
    'app.views.historique-ofpra'
    'app.views.extraction'
    'app.views.indicateurs_pilotage'
    'app.views.remise_titres'
    'app.views.aide'
  ])

  .run (Backend, BackendWithoutInterceptor, SETTINGS) ->
    Backend.setBaseUrl(SETTINGS.API_URL)
    BackendWithoutInterceptor.setBaseUrl(SETTINGS.API_URL)

  .config ($routeProvider, RestangularProvider) ->
    $routeProvider
      .when '/',
        redirectTo: '/accueil'
      .when '/profil',
        templateUrl: 'scripts/views/utilisateur/show_utilisateur.html'
        controller: 'ShowUtilisateurController'
        resolve: {$routeParams: -> return {'userId': 'moi'}}
        breadcrumbs: 'Profil'
      .when '/aide',
        templateUrl: 'scripts/views/aide/show_aide.html'
        controller: 'ShowAideController'
        breadcrumbs: 'Aide'
      .when '/403',
        templateUrl: '403.html'
      .when '/404',
        templateUrl: '404.html'
      .otherwise
        redirectTo: '/404'


  .directive 'navbarDirective', (evalCallDefered, $location, $rootScope, $route, $modal, SETTINGS, session, Backend)->
    restrict: 'E'
    scope: {}
    templateUrl: 'navbar.html'
    link: ($scope, elem, attrs) ->
      $scope.featureFlipping = SETTINGS.FEATURE_FLIPPING
      # Handle breadcrumbs when the route change
      loadBreadcrumbs = (currentRoute) ->
        if currentRoute.breadcrumbs?
          breadcrumbsDefer = evalCallDefered(currentRoute.breadcrumbs)
          breadcrumbsDefer.then (breadcrumbs) ->
            # As shorthand, breadcrumbs can be a single string
            if typeof(breadcrumbs) == "string"
              $scope.breadcrumbs = [[breadcrumbs, '']]
            else
              $scope.breadcrumbs = breadcrumbs
        else
          $scope.breadcrumbs = []

      loadBreadcrumbs($route.current.$$route)
      $rootScope.$on '$routeChangeSuccess', (currentRoute, previousRoute) ->
        loadBreadcrumbs($route.current.$$route)
        return

      $scope.user = {}
      session.getUserPromise().then(
        (user) ->
          $scope.user = user

          # Add role label to user
          $scope.user.libelle_role = SETTINGS.ROLES[user.role]

          if user.site_affecte
            # Find site_affecte by ID via a promise
            Backend.one(user.site_affecte._links.self).get().then(
                (site) ->
                 # Add site_affecte label to user
                 $scope.user.libelle_site_affecte = site.libelle

                 # Disable the spinner waiting for angular
                 angular.element('.waiting-for-angular').hide()
            )

        (error) ->
          # Disable the spinner even after error
          angular.element('.waiting-for-angular').hide()
      )

      # Smooth scrolling for scroll to top
      $('.scroll-top').click ->
        $('body,html').animate { scrollTop: 0 }, 1000
        return

      $scope.changeAccreditation = session.changeAccreditation

      $scope.logout = ->
        session.logout()

      $scope.apropos = ->
        modalInstance = $modal.open(
          templateUrl: 'scripts/xin/modal/modal.html'
          controller: 'ModalInstanceForceConfirmController'
          backdrop: false
          keyboard: false
          resolve:
            message: ->
              return ""
            sub_message: ->
              return "Conformément au décret n°2010-112 du 2 février 2010 pris pour l'application des articles 9,10 et 12 de l'ordonnance n°2005-1516 du 8 décembre 2005 relative aux échanges électroniques entre les usagers et les autorités administratives et entre les autorités administratives, et après la délibération n° DGEF-SSI-001 de la commission d'homologation le 30 octobre 2015, une autorisation d'exploitation du télé-service SI ASILE a été prononcée. Cette autorisation d'exploitation est valable jusqu'au 1er mai 2016 et devra être renouvelée."
        )

      $scope.openModalToChangeHabilitations = ->
        modalInstance = $modal.open(
          templateUrl: 'scripts/xin/habilitations/modal/change_habilitations.html'
          controller: 'modalHabilitationsController'
          backdrop: false
          keyboard: false
          resolve:
            message: ->
              return "En validant, Vous allez changer d'habilitation"
            alert_displayed: ->
              return true
            cancel_displayed: ->
              return true
        )

      $scope.getNumberActiveAccreditations = ->
        i = 0
        for accreditation in $scope.user?.accreditations or []
          finValidite = accreditation.fin_validite
          if finValidite
            dateFinValidite = new Date(finValidite)
            if  dateFinValidite > Date.now()
              i = i + 1
          else
            i = i + 1
        return i


  .directive 'navigationbarDirective', (evalCallDefered, $location, $rootScope, $route, SETTINGS, session, NAVIGATIONBAR_CONFIG)->
    restrict: 'E'
    templateUrl: 'navigationbar.html'
    scope: {}
    link: ($scope, elem, attrs) ->
      $scope.user = {}
      $scope.PERMISSIONS = SETTINGS.PERMISSIONS
      $scope.ff_broker_rabbit = SETTINGS.FEATURE_FLIPPING.broker_rabbit

      session.getUserPromise().then (user) ->
        $scope.user = user.plain()

      elem.find('.active').removeClass('active')
      path = $route.current.$$route.originalPath
      pathConfig = NAVIGATIONBAR_CONFIG[path]

      elem.find(pathConfig.elToActivate).addClass('active')
      elem.find('.nav-title').html(pathConfig.htmlToRender)

  .directive 'resizableDirective', ($window) ->
    ($scope) ->
      $scope.updateMarginSize = ->
        $scope.marginTop = angular.element(".actionbar")[0].clientHeight + 12

      $scope.marginTop = 64

      angular.element($window).bind 'resize', ->
        $scope.updateMarginSize()
        $scope.$apply()

  .directive 'footerDirective', (BackendWithoutInterceptor) ->
    restrict: 'E'
    templateUrl: 'footer.html'
    link: ($scope) ->
      $scope.frontVersion = '1.5.4'
      BackendWithoutInterceptor.one('version').get().then (version) ->
        $scope.backVersion = version.version
