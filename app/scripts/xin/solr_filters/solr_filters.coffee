'use strict'

angular.module('xin.solrFilters', ['ngRoute', 'sc-toggle-switch', 'xin.solr_filter.modal'])
  .constant 'BOOLEAN_SETTINGS',
    VALUES:[
      { "id": "true", "libelle": "Oui" },
      { "id": "false", "libelle": "Non" },
      { "id": "undefined", "libelle": "Non défini(e)" }
    ]

  .directive 'solrFiltersDirective', ->
    restrict: 'EA'
    templateUrl: 'scripts/xin/solr_filters/solr_filters.html'
    controller: 'solrFiltersController'
    scope:
      lookup: '=?'
      avancedFilters: '=?'
      haveFilters: '=?'
      json: '@'

    # Completes JSON file path
    compile: (tElement, tAttrs) ->
      if (!tAttrs.json.endsWith(".json"))
        tAttrs.json = tAttrs.json + ".json"
      tAttrs.json  = "scripts/xin/solr_filters/json/" + tAttrs.json


  .controller 'solrFiltersController', ($scope, $location, $http, $route, $routeParams, DelayedEvent) ->

    # Read data from a specific json file
    $http.get($scope.json)
      .success( (data) ->
        $scope.jsonData = data

        $scope.filters =
          'selectable': []                # List of selectable filters. Used by select-referential-directive
          'selected': []                  # List of selected filters
          'selectedId': []                # List of selected filters ID. Used by select-referential-directive
          'lastSpliceIndex': undefined    # Index of the deleted Referential. Used by select-referential-directive

        $scope.solr =
          'q': ''
          'fq': ''
          'filters': []                   # List of solr filters value

        # Creates the selectable filters List
        angular.forEach(data, (field, key) ->
          $scope.filters.selectable.push(
            id: key
            libelle: field.label
          )
        )

        $scope.generateFiltersFromURL()
      )
      .error( (data, status) ->
        $scope.error_json = "Le fichier JSON (" + $scope.json + ") n'a pa pu être récupéré."
      )

    ### Generates solr filters list from URL ###
    $scope.generateFiltersFromURL = ->
      if ($routeParams.q? and $routeParams.q != '')
        $scope.lookup.q = $routeParams.q
        $scope.solr.q = $routeParams.q.replace(RegExp(' AND ', 'g'), ' ')

      if ($routeParams.fq? and $routeParams.fq != '')
        $scope.lookup.fq = $routeParams.fq
        $scope.solr.fq = $routeParams.fq
        filtersTmp = $routeParams.fq.split(' AND ')
        for filter in filtersTmp
          fieldTmp = filter.substring(0, filter.indexOf('_phon'))
          if (fieldTmp == '')
            fieldTmp = filter.substring(0, filter.indexOf(':'))

          # If it is a 'undefined' BooleanFilter's field. cf. BOOLEAN_SETTINGS and $scope.$watch 'filterValue.boolean' in solrAvancedFilterController
          if (fieldTmp[0] == '-')
            fieldTmp = fieldTmp.substring(1, fieldTmp.length)

          angular.forEach($scope.jsonData, (field, key) ->
            if (field.field == fieldTmp)
              $scope.filters.selectedId.push(key)
              $scope.filters.selected.push(angular.copy(field))
              $scope.solr.filters.push(angular.copy(filter))
          )

      if ($routeParams.per_page? and $routeParams.per_page != '')
        $scope.lookup.per_page = $routeParams.per_page
      else
        $scope.lookup.per_page = '12'
        $location.search("per_page", '12').replace()

      if ($routeParams.page? and $routeParams.page != '')
        $scope.lookup.page = $routeParams.page
      else
        $scope.lookup.page = '1'
        $location.search("page", '1').replace()

      if ($routeParams.sort? and $routeParams.sort != '')
        $scope.lookup.sort = $routeParams.sort

    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)

    ### Force reloading ###
    $scope.$on('$routeUpdate', ->
      if (!$routeParams.q? and !$routeParams.fq? and !$routeParams.per_page? and !$routeParams.page?)
        $route.reload()
    )

    ### Updates URL ###
    $scope.$watch 'lookup.per_page', (value) ->
      if (value? && value != '')
        if ($scope.lookup.page != '1')
          $scope.lookup.page = '1'
          $location.search("per_page", value).replace()

    ### Updates URL ###
    $scope.$watch 'lookup.page', (value) ->
      if (value? && value != '')
        $location.search("page", value).replace()

    ### Updates URL ###
    $scope.$watch 'lookup.sort', (value) ->
      if (value? && value != '')
        $location.search("sort", value).replace()

    ### Generates the solr Q request ###
    $scope.$watch 'solr.q', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          # Replace whitespace with ' AND '
          filterValue = filterValue.replace(RegExp('\\s+', 'g'), ' AND ')
          $scope.lookup.q = filterValue
          # Update URL without reload. Directive option -> reloadOnSearch: false
          $location.search("q", filterValue).replace()
        else if $scope.lookup.q?
          delete $scope.lookup.q
          # Update URL without reload. Directive option -> reloadOnSearch: false
          $location.search("q", null).replace()

    ### Generates the solr FQ request from the solr filters list ###
    $scope.$watchCollection 'solr.filters', (filtersValue) ->
      delayedFilter.triggerEvent ->
        if (filtersValue?)
          $scope.solr.fq = ''
          for filterValue in filtersValue
            if (filterValue? and filterValue != '')
              if ($scope.solr.fq == '')
                $scope.solr.fq = filterValue
              else
                $scope.solr.fq = $scope.solr.fq + ' AND ' + filterValue
          if ($scope.solr.fq != '')
            $scope.haveFilters = true
            if ($routeParams.planning? and $routeParams.planning != '')
              $scope.planning = 'rendez_vous_gu_date:[' + moment($routeParams.planning).format('YYYY-MM-DD[T]00:00:00[Z]') + ' TO ' + moment($routeParams.planning).add(1, 'days').format('YYYY-MM-DD[T]00:00:00[Z]') + ']'
              $scope.lookup.fq = $scope.planning + ' AND ' + $scope.solr.fq
            else
              $scope.lookup.fq = $scope.solr.fq
            # Update URL without reload. Directive option -> reloadOnSearch: false
            $location.search("fq", $scope.solr.fq).replace()
          else if $scope.lookup.fq?
            $scope.haveFilters = false
            if ($routeParams.planning? and $routeParams.planning != '')
              $scope.planning = 'rendez_vous_gu_date:[' + moment($routeParams.planning).format('YYYY-MM-DD[T]00:00:00[Z]') + ' TO ' + moment($routeParams.planning).add(1, 'days').format('YYYY-MM-DD[T]00:00:00[Z]') + ']'
              $scope.lookup.fq = $scope.planning
            else
              delete $scope.lookup.fq
            # Update URL without reload. Directive option -> reloadOnSearch: false
            $location.search("fq", null).replace()

    ### Update the solr filters list after deleting a Referential. cf. select-referential-directive ###
    $scope.$watch 'filters.lastSpliceIndex', (value) ->
      if (value?)
        $scope.filters.selected.splice(value, 1)
        $scope.solr.filters.splice(value, 1)
        $scope.filters.lastSpliceIndex = undefined

    ### Update the solr filters list after adding a Referential. cf. select-referential-directive ###
    $scope.$watch 'filters.selectedId.length', (lengthValue, oldLengthValue) ->
      if (lengthValue > oldLengthValue)
        $scope.filters.selected.push(angular.copy($scope.jsonData[$scope.filters.selectedId[lengthValue - 1]]))
        $scope.solr.filters.push('')


  .directive 'solrAvancedFilterDirective', ->
    restrict: 'EA'
    templateUrl: 'scripts/xin/solr_filters/directive/solr_avanced_filter.html'
    controller: 'solrAvancedFilterController'
    scope:
      solr: '=?'
      filter: '=?'

  .controller 'solrAvancedFilterController', ($scope, $modal, BOOLEAN_SETTINGS) ->
    $scope.filterValue =
      text: ''
      address: ''
      identifier: ''
      boolean: ''
      beginDate: ''
      endDate: ''
      phonetisable: undefined

    if ($scope.filter? and $scope.filter.phonetisable? and $scope.filter.phonetisable.value?)
      $scope.filterValue.phonetisable = $scope.filter.phonetisable.value

    # Completes select-referential-directive / simple-text-input and date-text-input from the solr filter value ###
    if ($scope.solr? and $scope.solr.length > 0 and $scope.filter?)
      if ($scope.filter.type == 'text')
        $scope.filterValue.text = $scope.solr.substring($scope.solr.indexOf(':') + 1, $scope.solr.length)
        $scope.filterValue.phonetisable = true
        if ($scope.solr.substring(0, $scope.solr.indexOf('_phon')) == '')
          $scope.filterValue.phonetisable = false

      if ($scope.filter.type == 'address')
        # /!\ We must remove double quote
        $scope.filterValue.address = $scope.solr.substring($scope.solr.indexOf(':') + 2, $scope.solr.length - 1)

      else if ($scope.filter.type == 'identifier')
        $scope.filterValue.identifier = $scope.solr.substring($scope.solr.indexOf(':') + 1, $scope.solr.length)

      else if ($scope.filter.type == 'boolean')
        $scope.filterValue.boolean = $scope.solr.substring($scope.solr.indexOf(':') + 1, $scope.solr.length)
        if ($scope.filterValue.boolean == '*')
          $scope.filterValue.boolean = "undefined"

      else if ($scope.filter.type == 'date')
        $scope.filterValue.beginDate = $scope.solr.substring($scope.solr.indexOf('[') + 1, $scope.solr.indexOf(' TO '))
        $scope.filterValue.endDate = $scope.solr.substring($scope.solr.indexOf(' TO ') + 4, $scope.solr.indexOf(']'))

    if ($scope.filter.type == 'text')
      ### Show Information about solr request ###
      $scope.information = ->
        modalInstance = $modal.open(
          templateUrl: 'scripts/xin/solr_filters/modal/information_text.html'
          controller: 'ModalInstanceInformationController'
        )

      $scope.getTextFilter = ->
        if ($scope.filterValue.text? and $scope.filterValue.text != '')
          if ($scope.filterValue.phonetisable)
            $scope.solr = $scope.filter.field + '_phon:' + $scope.filterValue.text
          else
            $scope.solr = $scope.filter.field + ':' + $scope.filterValue.text
        else
          $scope.solr = ''

      $scope.$watch 'filterValue.phonetisable', (value) ->
        $scope.getTextFilter()

      $scope.$watch 'filterValue.text', (value) ->
        $scope.getTextFilter()

    if ($scope.filter.type == 'address')
      ### Show Information about solr request ###
      $scope.information = ->
        modalInstance = $modal.open(
          templateUrl: 'scripts/xin/solr_filters/modal/information_address.html'
          controller: 'ModalInstanceInformationController'
        )

      $scope.$watch 'filterValue.address', (value) ->
        if value? and value != ''
          $scope.solr = $scope.filter.field + ':"' + value + '"'
        else
          $scope.solr = ''

    if ($scope.filter.type == 'identifier')
      ### Show Information about solr request ###
      $scope.information = ->
        modalInstance = $modal.open(
          templateUrl: 'scripts/xin/solr_filters/modal/information_identifier.html'
          controller: 'ModalInstanceInformationController'
        )

      $scope.$watch 'filterValue.identifier', (value) ->
        if value? and value != ''
          $scope.solr = $scope.filter.field + ':' + value
        else
          $scope.solr = ''

    if ($scope.filter.type == 'boolean')
      $scope.booleanChoices = BOOLEAN_SETTINGS.VALUES
      if $scope.filter.libelles?
        for libelle, i in $scope.filter.libelles when i < 3
          $scope.booleanChoices[i].libelle = libelle
      ### Show Information about solr request ###
      $scope.information = ->
        modalInstance = $modal.open(
          templateUrl: 'scripts/xin/solr_filters/modal/information_identifier.html'
          controller: 'ModalInstanceInformationController'
        )

      $scope.$watch 'filterValue.boolean', (value) ->
        if value? and value != ''
          if (value == "undefined")
            $scope.solr = '-' + $scope.filter.field + ':*'
          else if (value == "true" or value == "false")
            $scope.solr = $scope.filter.field + ':' + value
        else
          $scope.solr = ''



    if ($scope.filter.type == 'date')
      ### Show Information about solr request ###
      $scope.information = ->
        modalInstance = $modal.open(
          templateUrl: 'scripts/xin/solr_filters/modal/information_date.html'
          controller: 'ModalInstanceInformationController'
        )

      $scope.$watch 'filterValue.beginDate', (value) ->
        if (value? and value != '')
          if ($scope.filterValue.endDate? and $scope.filterValue.endDate != '')
            $scope.solr = $scope.filter.field + ':[' + value + ' TO ' + $scope.filterValue.endDate + ']'
          else
            $scope.solr = $scope.filter.field + ':[' + value + ' TO *]'
        else
          if ($scope.filterValue.endDate? and $scope.filterValue.endDate != '')
            $scope.solr = $scope.filter.field + ':[* TO ' + $scope.filterValue.endDate + ']'
          else
            $scope.solr = ''

      $scope.$watch 'filterValue.endDate', (value) ->
        if (value? and value != '')
          value = moment(value).format('YYYY-MM-DD[T]23:59:59[Z]')
          if ($scope.filterValue.beginDate? and $scope.filterValue.beginDate != '')
            $scope.solr = $scope.filter.field + ':[' + $scope.filterValue.beginDate + ' TO ' + value + ']'
          else
            $scope.solr = $scope.filter.field + ':[* TO ' + value + ']'
        else
          if ($scope.filterValue.beginDate? and $scope.filterValue.beginDate != '')
            $scope.solr = $scope.filter.field + ':[' + $scope.filterValue.beginDate + ' TO *]'
          else
            $scope.solr = ''
