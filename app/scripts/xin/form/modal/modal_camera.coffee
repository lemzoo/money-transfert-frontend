'use strict'


angular.module('xin.form.camera.modal', ['xin.camera'])
  .controller 'ModalCameraController', ($scope, $modalInstance, downloadIfNotCamera, errorMessageIfNotCamera) ->
    $scope.photoToModify = null
    $scope.cameraActiv = false
    $scope.cameraError = false
    $scope.downloadIfNotCamera = downloadIfNotCamera
    $scope.errorMessageIfNotCamera = errorMessageIfNotCamera

    # check firefox version
    $scope.restrictFirefox = false
    userAgents = navigator.userAgent.split(" ")
    for userAgent in userAgents
      if userAgent.search("Firefox") != -1
        firefox = userAgent.split("/")
        version = firefox[1]
        if version < 24.0
          $scope.restrictFirefox = true
        break

    $scope.onCameraError = (error) ->
      $scope.cameraError = error
      $scope.$apply()

    $scope.snap = ->
      $modalInstance.close(
        status: "SNAP"
        photo: $scope.photoToModify
      )

    $scope.showUploader = ->
      $modalInstance.close(
        status: "UP"
      )

    $scope.cancel = ->
      $modalInstance.dismiss('cancel')
