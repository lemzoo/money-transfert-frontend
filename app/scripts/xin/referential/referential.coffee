'use strict'


angular.module('xin.referential', ['infinite-scroll'])
  .directive 'selectReferentialDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/referential/select_referential.html'
    controller: 'SelectReferentialController'
    scope:
      several: '=?'
      model: '=?'
      modelListener: '=?'
      errorModel: '=?'
      url: '=?'
      label: '=?'
      icon: '=?'
      placeholder: '=?'
      multiOne: '=?'
      refDisabled: '=?'
      choices: '=?'
      libelles: '=?'
      lastSpliceIndex: '=?'
    link: (scope, elem, attrs) ->
      return



  .controller 'SelectReferentialController', ($scope, $http, DelayedEvent,
                                              BackendWithoutInterceptor,
                                              removeDiacritics) ->
    Backend = BackendWithoutInterceptor

    # all elements selected
    $scope.choosen = []
    # Store all elements retrieving with backend.
    $scope.referentialSearchs = []
    # String use to search in backend.
    $scope.referentialSearch = ''
    # Object returns by backend after searching (use it to find 'next' page)
    $scope.referentials = null
    # Display the result of searching or not.
    $scope.referentialsDisplay = false

    $scope.referential_changed = false
    baseUrl = ""
    model = null
    modelType = ""

    if not $scope.model? and ($scope.several == true or $scope.multiOne == true)
      $scope.model = []

    # Init referential
    $scope.$watch 'model', (value) ->
      model = value
      computeModel()

    $scope.$watch 'url', (value) ->
      if value? and value != ""
        baseUrl = value
        if baseUrl.indexOf('?') > 0
          baseUrl = baseUrl.substr(0, baseUrl.indexOf('?'))
        computeModel()

    $scope.$watch 'choices', (value) ->
      if !$scope.url
        if value?
          $scope.referentials = value
          $scope.searchReferentials = []
          for referential in value
            $scope.searchReferentials.push(referential)

          if ($scope.choosen && not $scope.model in $scope.choosen) or $scope.model == null
            $scope.choosen = []

        else
          $scope.choosen = []
          $scope.searchReferentials = []
          $scope.model = null

    $scope.$watch 'modelListener', (value) ->
      if $scope.several == true
        $scope.origin_referential = []
        for key, value of $scope.model
          $scope.origin_referential[key] = value
      else
        $scope.origin_referential = $scope.model

    $scope.compute_referentialChanged = ->
      referential_changed = false
      if $scope.several == true
        if $scope.model.length != $scope.origin_referential.length
          referential_changed = true
        for key, referential of $scope.model
          if !$scope.origin_referential[key]? or $scope.origin_referential[key] != referential
            referential_changed = true
      else
        if $scope.model != $scope.origin_referential
          referential_changed = true
      $scope.referential_changed = referential_changed

    $scope.deleteReferential = (key) ->
      code = $scope.choosen[key].code
      $scope.lastSpliceIndex = key
      $scope.choosen.splice(key, 1)
      if $scope.several == true
        for model, index in $scope.model or []
          if modelType == "object"
            if model.code == code
              $scope.model.splice(index, 1)
              break
          else
            if model == code
              $scope.model.splice(index, 1)
              break
      else if $scope.multiOne == true
        $scope.model = []
      else
        $scope.model = ''
      $scope.compute_referentialChanged()

    $scope.referentialInputFocus = ->
      if $scope.url? and $scope.url != ''
        $scope.filter_search('*')
      $scope.referentialsDisplay = true

    $scope.referentialInputBlur = ->
      $scope.referentialSearch = ""
      $scope.referentialsDisplay = false

    delayedFilter = new DelayedEvent(500)

    $scope.filter_search = (filterValue) ->
      delayedFilter.triggerEvent ->
        if $scope.url? and $scope.url != ""
          if filterValue? and filterValue != ''
            separator = '?'
            if $scope.url.indexOf('?') > -1
              separator = '&'
            url = $scope.url + separator + "q=*" + filterValue + "*"

            firstFilterChar = filterValue.charAt(0)
            lastFilterChar = filterValue.charAt(filterValue.length - 1)

            if (firstFilterChar == '"' and lastFilterChar == '"') or (firstFilterChar == "'" and lastFilterChar == "'")
              url = $scope.url + separator + "q=" + filterValue

            $scope.errorModel = false
            Backend.all(url).getList().then(
              (referentials) ->
                $scope.referentials = referentials
                $scope.searchReferentials = []
                for referential in referentials
                  $scope.searchReferentials.push(referential)
              (error) ->
                if error.status == 404
                  $scope.errorModel = "Aucun résultat trouvé"
                else if error.status == 403
                  $scope.errorModel = "Accès non autorisé au référentiel"
                else
                  $scope.errorModel = "Une erreur inattendue s'est produite. Veuillez contacter votre administrateur."
            )
          else
            $scope.errorModel = false
            Backend.all($scope.url).getList().then(
              (referentials) ->
                $scope.referentials = referentials
                $scope.searchReferentials = []
                for referential in referentials
                  $scope.searchReferentials.push(referential)
              (error) ->
                if error.status == 404
                  $scope.errorModel = "Aucun résultat trouvé"
                else if error.status == 403
                  $scope.errorModel = "Accès non autorisé au référentiel"
                else
                  $scope.errorModel = "Une erreur inattendue s'est produite. Veuillez contacter votre administrateur."
            )

        else if $scope.choices
          if filterValue and filterValue != ''
            filterStr = removeDiacritics(filterValue)
            filterStr = filterStr.toLowerCase()
            $scope.searchReferentials = []
            for referential in $scope.choices
              libelle = removeDiacritics(referential.libelle)
              libelle = libelle.toLowerCase()
              if (libelle.indexOf(filterStr) > -1)
                $scope.searchReferentials.push(referential)
          else
            $scope.referentials = $scope.choices
            $scope.searchReferentials = []
            for referential in $scope.choices
              $scope.searchReferentials.push(referential)

    $scope.$watch 'referentialSearch', (filterValue, oldFilterValue) ->
      if (!filterValue? or filterValue == '') and (!oldFilterValue? or oldFilterValue == '')
        return
      $scope.filter_search(filterValue)

    $scope.loadMoreReferentials = ->
      if $scope.referentials? and $scope.referentials._links.next?
        $scope.errorModel = false
        Backend.all($scope.referentials._links.next).getList().then(
          (referentials) ->
            for referential in referentials
              $scope.searchReferentials.push(referential)
            $scope.referentials = referentials
          (error) ->
            if error.status == 404
              $scope.errorModel = "Aucun résultat trouvé"
            else if error.status == 403
              $scope.errorModel = "Accès non autorisé au référentiel"
            else
              $scope.errorModel = "Une erreur inattendue s'est produite. Veuillez contacter votre administrateur."
        )

    $scope.clickReferential = (searchReferential) ->
      if $scope.several == true or $scope.multiOne == true
        $scope.choosen.push({code: searchReferential.id, libelle: searchReferential.libelle})
        if modelType == "object"
          $scope.model.push({code: searchReferential.id, libelle: searchReferential.libelle})
        else
          $scope.model.push(searchReferential.id)
      else
        $scope.choosen = []
        $scope.choosen.push({code: searchReferential.id, libelle: searchReferential.libelle})
        if modelType == "object"
          $scope.model = {code: searchReferential.id, libelle: searchReferential.libelle}
        else
          $scope.model = searchReferential.id
      $scope.libelles = []
      for choice in $scope.choosen
        $scope.libelles.push(choice.libelle)
      $scope.referentialsDisplay = false
      $scope.referentialSearch = ''
      $scope.compute_referentialChanged()

    computeModel = ->
      $scope.choosen = []
      if not model?
        return
      if typeof(model) == "string"
        computeString(model)
      else if model instanceof Array
        computeArray(model)
      else if typeof(model) == "object"
        computeObject(model)

    computeString = (value, index=null) ->
      if modelType == ""
        modelType = "string"
      if value == ""
        return
      if baseUrl != ""
        $scope.errorModel = false
        Backend.one(baseUrl + '/' + value).get().then(
          (referential) ->
            if index?
              $scope.choosen[index] = {code: value, libelle: referential.libelle}
            else
              $scope.choosen.push({code: value, libelle: referential.libelle})
          (error) ->
            if error.status == 404
              $scope.errorModel = "Aucun résultat trouvé"
            else if error.status == 403
              $scope.errorModel = "Accès non autorisé au référentiel"
            else
              $scope.errorModel = "Une erreur inattendue s'est produite. Veuillez contacter votre administrateur."
        )
      else if $scope.choices?
        for choice in $scope.choices
          if choice.id == value
            $scope.choosen.push({code: value, libelle: choice.libelle})

    computeArray = (value) ->
      for item, index in value or []
        if typeof(item) == "string" or typeof(item) == "number"
          computeString(item, index)
        else
          computeObject(item, index)

    computeObject = (value, index=null) ->
      if modelType == ""
        modelType = "object"
      if not value?
        return
      if value.libelle?
        $scope.choosen.push(value)
      else if value.code?
        if baseUrl != ""
          $scope.errorModel = false
          Backend.one(baseUrl + '/' + value.code).get().then(
            (referential) ->
              if index?
                $scope.choosen[index] = {code: referential.code, libelle: referential.libelle}
              else
                $scope.choosen.push({code: referential.code, libelle: referential.libelle})
            (error) ->
              if error.status == 404
                $scope.errorModel = "Aucun résultat trouvé"
              else if error.status == 403
                $scope.errorModel = "Accès non autorisé au référentiel"
              else
                $scope.errorModel = "Une erreur inattendue s'est produite. Veuillez contacter votre administrateur."
          )
        else if $scope.choices?
          for choice in $scope.choices
            if choice.id == value.code
              $scope.choosen.push({code: value.code, libelle: choice.libelle})
      else if value.id?
        if baseUrl != ""
          $scope.errorModel = false
          Backend.one(baseUrl, value.id).get().then(
            (referential) ->
              if index?
                $scope.choosen[index] = {code: referential.code, libelle: referential.libelle}
              else
                $scope.choosen.push({code: referential.code, libelle: referential.libelle})
            (error) ->
              if error.status == 404
                $scope.errorModel = "Aucun résultat trouvé"
              else if error.status == 403
                $scope.errorModel = "Accès non autorisé au référentiel"
              else
                $scope.errorModel = "Une erreur inattendue s'est produite. Veuillez contacter votre administrateur."
          )
        else if $scope.choices?
          for choice in $scope.choices
            if choice.id == value.id
              $scope.choosen.push({code: value.id, libelle: choice.libelle})
