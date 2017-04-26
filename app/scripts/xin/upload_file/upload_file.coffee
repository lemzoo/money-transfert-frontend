'use strict'


angular.module('xin.uploadFile', ['app.settings', 'angularFileUpload'])
  .directive 'uploadFileDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/upload_file/upload_file.html'
    controller: 'UploadFileController'
    scope:
      uploader: '=?'
      mimes: '=?'
      max: '=?'
      uploadInProgress: '=?'
      hideButtons: '=?'
    link: (scope, elem, attrs) ->
      drop = elem.find('.drop')
      input = drop.find('input')
      scope.$watch 'max', (max) ->
        if not max
          input.attr('multiple', '')
        else if max > 1
          input.attr('multiple', '')
          scope.addMaxFilter(max)
        else
          scope.addMaxFilter(max)
      scope.$watch 'mimes', (mimes) ->
        if mimes? and mimes.length
          scope.addMimesFilter(mimes)
      if !scope.uploadInProgress?
        scope.uploadInProgress = false
      scope.clickFileInput = ->
        input.click()
        return


  .controller 'UploadFileController', ($scope, SETTINGS, sessionTools, FileUploader) ->
    url = SETTINGS.API_URL + '/fichiers'
    uploader = $scope.uploader = new FileUploader(
      url: url
      withCredentials: true
      headers:
        Authorization: sessionTools.getAuthorizationHeader()
    )

    $scope.addMaxFilter = (max) ->
      uploader.filters.push(
        name: "Nombre maximum de fichier atteint ("+max+")."
        fn: (item, options) ->
          return this.queue.length < max
      )

    $scope.addMimesFilter = (mimes) ->
      uploader.filters.push(
        name: "Extension non autorisée. Liste des types autorisées : "+mimes+"."
        fn: (item, options) ->
          result = false
          for mime in mimes or []
            if item.type == mime
              return true
          return false
      )

    # angular-file-upload CALLBACKS
    uploader.onWhenAddingFileFailed = (item, filter, options) ->
      text = "Le fichier "+item.name+" n'a pas pu être ajouté à la liste. "+
             filter.name
      $scope.error =
        text: text
#      console.info('onWhenAddingFileFailed', item, filter, options)
#    uploader.onAfterAddingFile = (fileItem) ->
#      console.info('onAfterAddingFile', fileItem)
#    uploader.onAfterAddingAll = (addedFileItems) ->
#      console.info('onAfterAddingAll', addedFileItems)
#    uploader.onBeforeUploadItem = (item) ->
#      console.info('onBeforeUploadItem', item)
#    uploader.onProgressItem = (fileItem, progress) ->
#      console.info('onProgressItem', fileItem, progress)
    uploader.onProgressAll = (progress) ->
      $scope.uploadInProgress = true
    uploader.onSuccessItem = (fileItem, response, status, headers) ->
      fileItem.id = response.id
      fileItem._links =
        data: response._links.data
      fileItem.name = response.name
#      console.info('onSuccessItem', fileItem, response, status, headers)
#    uploader.onErrorItem = (fileItem, response, status, headers) ->
#      console.info('onErrorItem', fileItem, response, status, headers)
#    uploader.onCancelItem = (fileItem, response, status, headers) ->
#      console.info('onCancelItem', fileItem, response, status, headers)
#    uploader.onCompleteItem = (fileItem, response, status, headers) ->
#      console.info('onCompleteItem', fileItem, response, status, headers)
    uploader.onCompleteAll = () ->
      $scope.uploadInProgress = false


#      console.info('onCompleteAll')

    # Custom methods
    uploader.isUploadComplete = ->
      for file in this.queue
        if not file.isUploaded
          $scope.uploadInProgress = true
          return false
      $scope.uploadInProgress = false
      return true
