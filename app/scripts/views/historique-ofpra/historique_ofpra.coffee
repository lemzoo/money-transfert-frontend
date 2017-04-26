'use strict'

breadcrumbsGetHistoriqueOfpraDefer = undefined

angular.module('app.views.historique-ofpra', ['app.settings', 'ngRoute', 'ui.bootstrap', 'xin.print', 'ui.calendar',
                                        'xin.listResource', 'xin.tools', 'ui.bootstrap.datetimepicker', 'xin.session',
                                        'xin.backend', 'angularMoment'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/historique-telem-ofpra',
        templateUrl: 'scripts/views/historique-ofpra/list_historique_ofpra.html'
        controller: 'ListHistoriqueOfpraController'
        breadcrumbs: 'Historique Accès Telem Ofpra'
        reloadOnSearch: false
        routeAccess: true,

  .controller 'ListHistoriqueOfpraController', ($scope, Backend, session, moment) ->
    $scope.lookup = {}
    $scope.resourceBackend = Backend.all('telemOfpra')
    $scope.links = null

    $scope.computeResource = (current_scope) ->
      setUser = (resource) ->
        Backend.one(resource.agent._links.self).get().then(
          (agent) ->
            resource.prenom = agent.prenom
            resource.nom = agent.nom
            resource.email = agent.email
        )

      for resource in current_scope.resources
        setUser(resource)
        resource.todo = true

    $scope.dtLoadingTemplate = ->
      return {
        html: '<img src="images/spinner.gif">'
      }
