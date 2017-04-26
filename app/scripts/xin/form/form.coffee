'use strict'

angular.module('xin.form', ['xin.photo', 'xin.uploadFile', 'ui.bootstrap.datetimepicker',
                            'angularMoment', 'xin.form.camera.modal', 'xin.form.array.modal'])

  .directive 'simpleTextInputDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/form/simple_text_input.html'
    controller: 'SimpleTextInputController'
    scope:
      formOrigin: '=?'
      formLabel: '=?'
      formLabelledBy: '=?'
      formError: '=?'
      formHide: '=?'
      formIcon: '=?'
      formNgModel: '=?'
      formPlaceholder: '=?'
      formDisabled: '=?'
      formName: '=?'
      formPopover: '=?'
      extendIcon: '=?'
      type: '=?'
      upperFirstLetter: '=?'
      maxlength: '@?'
      autofocusEnabled: '=?'
    link: (scope, elem, attrs) ->
      if scope.formPopover?
        $(elem).popover({
          trigger: 'focus'
          content: scope.formPopover
          placement: 'top'
        })

      if !scope.type?
        scope.type = 'text'

  .controller 'SimpleTextInputController', ($scope) ->
    $scope.onBlur = ->
      if $scope.formNgModel? and $scope.formNgModel != '' and
         typeof($scope.formNgModel) == "string"
        $scope.formNgModel = $scope.formNgModel.trim()
        if $scope.upperFirstLetter == true
          $scope.formNgModel = $scope.formNgModel.charAt(0).toUpperCase() + $scope.formNgModel.slice(1)



  .directive 'photoDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/form/photo.html'
    controller: 'PhotoController'
    scope:
      photoLabel: '=?'
      photoOrigin: '=?'
      photoError: '=?'
      photoDisabled: '=?'
      usager: '=?'
      photo: '=?'
      downloadIfNotCamera: '=?'
      errorMessageIfNotCamera: '=?'
    link: (scope, elem, attrs) ->
      return

  .controller 'PhotoController', ($scope, $modal, SETTINGS, session) ->
    $scope.takePhoto = true
    $scope.uploadPhoto = false
    $scope.modifyPhoto = false
    $scope.photoToModify = null
    $scope.refreshCanvas = false
    $scope.uploader = {}
    $scope.photoFile = {}
    $scope.api_url = SETTINGS.API_BASE_URL
    spa = false

    session.getUserPromise().then (user) ->
      if user.role in ["GESTIONNAIRE_PA", "RESPONSABLE_PA"]
        spa = true

    $scope.$watch 'photo', (value) ->
      if value == null
        $scope.uploader.queue = []
        $scope.takePhoto = true
        $scope.uploadPhoto = false
        $scope.modifyPhoto = false

    $scope.$watch 'usager', (value) ->
      if value?.photo?
        $scope.takePhoto = false
      else if spa and value?.photo_premier_accueil?
        $scope.takePhoto = false
    , true

    $scope.loadPhoto = ->
      if $scope.photoDisabled
        return
      $scope.uploader.queue = []
      $scope.showCamera()

    $scope.$watch 'uploader.queue[0]', (file, oldFile) ->
      if file?
        $scope.takePhoto = false
        $scope.uploadPhoto = false
        $scope.modifyPhoto = true
        $scope.photoToModify = file._file

    $scope.$watch 'photoFile', (photoFile) ->
      if photoFile? && photoFile.id?
        $scope.photo =
          id: photoFile.id
          _links: photoFile._links
          not_save: true
        $scope.modifyPhoto = false

    $scope.cancelEditPhoto = ->
      $scope.uploader.queue = []
      $scope.modifyPhoto = false
      if $scope.photo?
        $scope.takePhoto = false
      else
        $scope.takePhoto = true

    $scope.closedPhoto = ->
      $scope.uploadPhoto = false
      if $scope.photo?
        $scope.takePhoto = false
      else
        $scope.takePhoto = true

    $scope.deletePhoto = ->
      $scope.uploader.queue = []
      $scope.photo = null
      $scope.takePhoto = true

    $scope.documentsInProgress = false
    $scope.$watch 'documentsInProgress', (value, oldValue) ->
      if value == false and oldValue == true
        if !$scope.usager.documents?
          $scope.usager.documents = []
        for usager_document in $scope.uploader_documents.queue
          if usager_document.id?
            new_document =
              id: usager_document.id
              _links: usager_document._links
              name: usager_document.name
              not_save: true
            $scope.usager.documents.push(new_document)
        $scope.uploader_documents.queue = []
        $scope.uploader_documents.progress = 0

    $scope.showCamera = ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/form/modal/camera.html'
        controller: 'ModalCameraController'
        resolve:
          downloadIfNotCamera: ->
            return $scope.downloadIfNotCamera
          errorMessageIfNotCamera: ->
            return $scope.errorMessageIfNotCamera
      )
      modalInstance.result.then(
        (result) ->
          $scope.takePhoto = false
          if result.status == 'SNAP'
            $scope.modifyPhoto = true
            $scope.photoToModify = result.photo
            $scope.refreshCanvas = true
          else
            $scope.uploadPhoto = true
      )



  .directive 'listTextInputDirective', ->
    restrit: 'E'
    templateUrl: 'scripts/xin/form/list_text_input.html'
    controller: 'ListTextInputController'
    scope:
      label: '=?'
      model: '=?'
      upperFirstLetter: '=?'
      originModel: '=?'
      error: '=?'
      icon: '=?'
      iconText: '@?'
      uDisabled: '=?'
      placeholder: '=?'
      popoverContent: '=?'
    link: (scope, elem, attrs) ->
      if scope.popoverContent?
        $(elem).popover({
          trigger: 'focus'
          content: scope.popoverContent
          placement: 'top'
        })
      return

  .controller 'ListTextInputController', ($scope) ->
    $scope.new_value = ''
    $scope.value_changed = false

    $scope.compute_valueChanged = ->
      value_changed = false
      if $scope.model.length != $scope.originModel.length
        value_changed = true
      for key, value of $scope.model
        if !$scope.originModel[key]? or $scope.originModel[key] != value
          value_changed = true
      $scope.value_changed = value_changed

    $scope.addValue = ->
      if $scope.new_value != '' and $scope.new_value != null and $scope.new_value != undefined
        $scope.new_value = $scope.new_value.trim()
        if $scope.upperFirstLetter == true
          $scope.new_value = $scope.new_value.charAt(0).toUpperCase() + $scope.new_value.slice(1)
        $scope.model.push($scope.new_value)
        $scope.new_value = ''
      $scope.compute_valueChanged()

    $scope.modifyValue = (key, value) ->
      if $scope.upperFirstLetter == true
        value = value.charAt(0).toUpperCase() + value.slice(1)
      $scope.model[key] = value

    $scope.deleteValue = (key) ->
      $scope.model[key] = ''
      new_values = []
      for value in $scope.model
        if value != ''
          new_values.push(value)
      $scope.model = new_values
      $scope.compute_valueChanged()


  .directive 'dateTextInputDirective', ->

    restrict: 'E'
    templateUrl: 'scripts/xin/form/date_text_input.html'
    controller: 'DateTextInputController'
    scope:
      label: '=?'
      active: '=?'
      model: '=?'
      originModel: '=?'
      error: '=?'
      approximative: '=?'
      approximativeModel: '=?'
      withHour: '=?'
      popoverContent: '=?'
    link: (scope, elem, attrs) ->
      if scope.popoverContent?
        $(elem).popover({
          trigger: 'focus'
          content: scope.popoverContent
          placement: 'top'
        })
      scope.today = false
      if attrs.today?
        scope.today = true


  .controller 'DateTextInputController', ($scope, moment) ->

    firstChange = false
    originModelChanged = false
    $scope.date_id = guid()

    $scope.$watch 'model', (value) ->
      if value
        setDate(value)
      else if not firstChange and $scope.today
        setDate()

    setDate = (value = null) ->
      $scope.textDate = ''
      date = null
      if value
        date = moment(value)
      else if not firstChange and $scope.today
        firstChange = true
        date = moment()
      else
        return
      if $scope.withHour == true
        newDate = date.format('DD/MM/YYYY HH:mm')
      else
        if date._tzm == 0
          date = date.utc()
        newDate = date.format('DD/MM/YYYY')
        $scope.model = date.format('YYYY-MM-DD[T]00:00:00[Z]')

      if newDate != 'Invalid date'
        $scope.textDate = newDate

    $scope.$watch 'originModel', (value) ->
      if not originModelChanged
        originModelChanged = true
      if value
        if not $scope.withHour
          $scope.originModel = moment(value).utc().format('YYYY-MM-DD[T]00:00:00[Z]')

    $scope.handleInputDate = ->
      $scope.error = ""
      if $scope.textDate
        testDate = moment($scope.textDate, "DD/MM/YYYY", true)
        if $scope.withHour == true
          testDate = moment($scope.textDate, "DD/MM/YYYY HH:mm", true)
        if testDate.isValid()
          if $scope.withHour == true
            $scope.model = testDate
          else
            $scope.model = testDate.format('YYYY-MM-DD[T]00:00:00[Z]')
        else
          if $scope.textDate == ''
            $scope.model = null
          else
            $scope.model = $scope.textDate
          $scope.error = $scope.textDate + " n'est pas une date valide."
      else
        $scope.model = null


    $scope.$watch 'error', (value) ->
      if Array.isArray(value)
        error_text = ""
        for errorString in value
          if errorString.indexOf("Could not deserialize") > -1
            error_text += "Date invalide"
          else
            error_text += errorString
        $scope.error = error_text
    , true



  .directive 'arrayInputDirective', ($modal) ->
    restrict: 'E'
    templateUrl: 'scripts/xin/form/array_input.html'
    scope:
      label: '=?'
      uDisabled: '=?'
      model: '=?'
      originModel: '=?'
      error: '=?'
    link: (scope, elem, attrs) ->
      scope.addRow = ->
        modalInstance = $modal.open(
          templateUrl: 'scripts/xin/form/modal/array.html'
          controller: 'ModalArrayController'
          resolve:
            row: ->
              return null
            origin_row: ->
              return null
        )
        modalInstance.result.then(
          (result) ->
            scope.model.push(result)
        )

      scope.editRow = (key) ->
        modalInstance = $modal.open(
          templateUrl: 'scripts/xin/form/modal/array.html'
          controller: 'ModalArrayController'
          resolve:
            row: ->
              return scope.model[key]
            origin_row: ->
              return scope.originModel[key]
        )
        modalInstance.result.then(
          (result) ->
            scope.model[key] = result
        )

      scope.deleteRow = (key) ->
        scope.model.splice(key, 1)



  .directive 'ngEnter', ->
    (scope, element, attrs) ->
      element.bind 'keydown keypress', (event) ->
        if event.which == 13
          scope.$apply ->
            scope.$eval attrs.ngEnter
            return
          event.preventDefault()
        return
      return


guid = ->
  s4 = ->
    Math.floor((1 + Math.random()) * 0x10000).toString(16).substring 1
  s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4()
