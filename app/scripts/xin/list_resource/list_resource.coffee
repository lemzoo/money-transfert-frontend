'use strict'

angular.module('xin.listResource', ['app.settings', 'ngRoute', 'angularUtils.directives.dirPagination', 'xin.session'])

  .config ($compileProvider, paginationTemplateProvider) ->
    paginationTemplateProvider.setPath('scripts/xin/list_resource/dirPagination.tpl.html')
    # Directive used to inject dynamic html node in the template
    $compileProvider.directive 'compile', ($compile) ->
      return (scope, element, attrs) ->
        scope.$watch(
          (scope) ->
            return scope.$eval(attrs.compile)
          (value) ->
            element.html(value)
            $compile(element.contents())(scope)
        )

  .controller 'ListResourceController', ($scope, $timeout, Backend, moment, $location, session, SETTINGS) ->
    session.getUserPromise().then (user) ->
      $scope.user = user.plain()
    $scope.resources = []
    $scope.roles = SETTINGS.ROLES
    $scope.settingsSites = SETTINGS.SITES
    $scope.loading = true
    $scope.api_url = SETTINGS.API_BASE_URL

    updateResourcesList = () ->
      $scope.loading = true
      if $scope.resourceBackend?
        resourceBackend = $scope.resourceBackend
        if $scope.abort?
          resourceBackend.withHttpConfig({timeout: $scope.abort.promise})
        resourceBackend.getList($scope.lookup).then(
          (items) ->
            $scope.resources = items
            $scope.links = items._links
            if $scope.customUpdateResourcesList?
              $scope.customUpdateResourcesList($scope)
            $scope.loading = false
          (error) ->
              console.log(error)
              $scope.resources = []
              if $scope.customUpdateResourcesList?
                $scope.customUpdateResourcesList($scope)
              $scope.loading = false
        )

    $scope.$watch 'lookup', (value) ->
      if(!angular.equals({}, value))
        updateResourcesList()
    , true

    $scope.pageChange = (newPage) ->
      if $scope.lookup.page == "#{newPage}"
        return
      $scope.lookup.page = "#{newPage}"

    $scope.displayListText = (list) ->
      if !list?
        return ""
      result_text = ""
      for item in list
        result_text = result_text + item + " "
      return result_text


  .directive 'listResourceDirective', (session, Backend) ->
    restrict: 'E'
    transclude: true
    templateUrl: 'scripts/xin/list_resource/list_resource.html'
    controller: 'ListResourceController'
    scope:
      resourceBackend: '='
      lookup: '=?'
      links: '=?'
      complement: '=?'
      customUpdateResourcesList: '=?'
      columnClassInfo: '=?'
      abort: '=?'
      others: '=?'
      customOperation: '&?'
      selected: '=?'

    link: (scope, elem, attrs, ctrl, transclude) ->

      scope.popoverIsVisible = {}

      scope.showPopover = (id) ->
        scope.popoverIsVisible = {}
        scope.popoverIsVisible[id] = true

      scope.hidePopover = (id) ->
        scope.popoverIsVisible[id] = false

      if attrs.others
        scope.$watch 'others', (others) ->
            for key, value of others
              scope[key] = value
          , true

      if not attrs.lookup?
        scope.lookup = {}

      if not attrs.columnClassInfo?
        scope.columnClassInfo = 'col-md-4'

      if !transclude
        throw "Illegal use of lgTranscludeReplace directive in the template," +
              " no parent directive that requires a transclusion found."
        return
      transclude (clone) ->
        scope.resourceTemplate = ''
        clone.each (index, node) ->
          if node.outerHTML?
            scope.resourceTemplate += node.outerHTML

  .directive 'listRoleDirective', (moment, SETTINGS) ->
    restrict: 'E'
    scope:
      accreditations: '='
    link: (scope, elem, attrs) ->
      scope.validRoles = []
      now = moment()
      popoverContent = []
      if scope.accreditations?
        for accreditation in scope.accreditations
          role = SETTINGS.ROLES[accreditation.role]
          fin_validite = moment(accreditation.fin_validite)
          if (not accreditation.fin_validite? or fin_validite > now) and scope.validRoles.indexOf(role) == -1
            scope.validRoles.push(role)

      if scope.validRoles.length == 0
        scope.validRoles.push("Aucune habilitation valide")

    template: '<ng-repeat ng-repeat="role in validRoles"><span class="badge">{{role}}</span><br></ng-repeat>'
