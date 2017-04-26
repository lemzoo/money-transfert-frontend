'use strict'


angular.module('xin.camera', ['app.settings'])
  .directive 'cameraDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/upload_file/photo/camera.html'
    controller: 'CameraController'
    scope:
      video: '=?'
      onError: '=?'
    link: (scope, elem, attrs) ->
      scope.video = elem.find("video")[0]


  .controller 'CameraController', ($scope, $window, SETTINGS, sessionTools) ->
    $scope.permissionDeniedErrorMessage = "Le navigateur n'est pas autorisé à utiliser votre appareil de capture vidéo."
    $scope.errorMessage = "Aucun appareil vidéo compatible détecté."

    errBack = (error) ->
      if error.name? and error.name == 'PermissionDeniedError'
        $scope.PermissionDeniedError = true
        $scope.onError?($scope.permissionDeniedErrorMessage)
      else
        $scope.error = true
        $scope.onError?($scope.errorMessage)

    # Put video listeners into place
    $scope.$watch 'video', (video) ->
      if not video?
        return
      videoObj =
        audio: false
        video: true

      navigator.getUserMedia = (navigator.getUserMedia or navigator.webkitGetUserMedia or
                                navigator.mozGetUserMedia or navigator.msGetUserMedia)
      if navigator.getUserMedia?
        navigator.getUserMedia(videoObj, (localMediaStream) ->
          $scope.video.src = window.URL.createObjectURL(localMediaStream)
          $scope.video.play()
        , errBack)
      else
        console.log("getUserMedia not supported")
