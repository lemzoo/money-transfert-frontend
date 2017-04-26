'use strict'

angular.module('app.views.extraction', ['ngRoute', 'app.settings',
                                        'xin.backend'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/extractions-base',
        templateUrl: 'scripts/views/extraction/extraction.html'
        controller: 'ExtractionController'
        routeAccess: true
        breadcrumbs: "Extractions base de données"



  .controller 'ExtractionController', ($scope, $modal, $route,
                                       Backend, session, SETTINGS) ->
    $scope.dateFrom = ""
    $scope.dateTo = ""
    $scope.csv_spinner = false
    $scope.PERMISSIONS = SETTINGS.PERMISSIONS

    $scope.user = {}
    session.getUserPromise().then (user) ->
      $scope.user = user.plain()

    ### Generate CSV file ###
    generateCSV = (name, route) ->
      tmpCSV = ""
      retrieveDataLoop = (link) ->
        if link
          Backend.one(link).get().then(
            (data) ->
              tmpCSV = tmpCSV + data._data
              retrieveDataLoop(data._links.next)
          )
        else
          # Generate CSV
          anchor = angular.element('a')
          angular.element(document.body).append(anchor)
          blob = new Blob([tmpCSV], {type: "text/csv;charset=utf-8"})
          anchor.attr(
            href: window.URL.createObjectURL(blob)
            target: "_blank"
            download: "export_#{name}.csv"
          )[0].click()
          anchor.remove()
          $route.reload()

      # Retrive Data and generate CSV
      $scope.csv_spinner = true
      retrieveDataLoop(route)


    $scope.createCSV = (name) ->
      # Check Dates
      if $scope.dateFrom == "Invalid date" or $scope.dateTo == "Invalid date"
        return

      duration = moment($scope.dateTo).diff(moment($scope.dateFrom), "days")
      $scope.error = undefined
      if duration < 0
        $scope.error = "Veuillez sélectionner une période valide.\nLa date de début doit commencer avant la date de fin de période."
        return

      # Created Date range
      fq = "fq=doc_created:["
      if not $scope.dateFrom? or $scope.dateFrom == ''
        fq = fq + "* TO "
      else
        fq = fq + $scope.dateFrom + " TO "

      if not $scope.dateTo? or $scope.dateTo == ''
        fq = fq + "*]"
      else
        fq = fq + moment($scope.dateTo).format('YYYY-MM-DD[T]23:59:59[Z]') + "]"

      generateCSV(name, name + '/export?' + fq + "&per_page=50")
