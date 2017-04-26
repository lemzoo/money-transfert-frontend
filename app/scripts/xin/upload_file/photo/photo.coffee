'use strict'


angular.module('xin.photo', ['app.settings'])
  .directive 'editPhotoDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/upload_file/photo/edit_photo.html'
    controller: 'EditPhotoController'
    scope:
      file: '='
      generatedFile: '='
      cancel: '=?'
      refresh: '=?'
    link: (scope, elem, attrs) ->
      scope.canvas = elem.find("canvas")
      scope.$watch 'file', (file) ->
        if file? and file.nodeName != 'VIDEO'
          scope.displayPhoto(file)
      scope.$watch 'refresh', (value) ->
        if not value
          return
        else
          scope.displaySnap()
          scope.refresh = false


  .controller 'EditPhotoController', ($scope, $http, $window, SETTINGS, sessionTools, Backend) ->
    ctx = null
    dradding = false
    ratio = 0
    width_ori = 0
    height_ori = 0
    sx = 0
    sy = 0
    swidth = 0
    sheight = 0
    x = 0
    y = 0
    width = 0
    height = 0

    $scope.$watch 'canvas', (canvas) ->
      ctx = canvas[0].getContext("2d")
      canvas.bind("wheel", onMouseWheel)
      canvas.bind("mousedown", onMouseDown)
      canvas.bind("mouseup", onMouseUp)
      canvas.bind("mousemove", onMouseMove)

    reader = new FileReader()
    reader.onload = (e) ->
      photo.src = e.target.result

    photo = new Image()
    photo.onload = ->
      ctx.clearRect(0, 0, $scope.canvas[0].width, $scope.canvas[0].height)
      # http://www.w3schools.com/tags/canvasdrawimage.asp
      width_ori = this.width
      height_ori = this.height
      # display the all image inside canvas
      ratio = height_ori / width_ori
      sx = 0
      sy = 0
      swidth = width_ori
      sheight = height_ori

      # compute new size image
      if ratio < $scope.canvas[0].height / $scope.canvas[0].width
        width = $scope.canvas[0].width
        height = width * ratio
      else
        height = $scope.canvas[0].height
        width = height / ratio

      # place image
      if width == $scope.canvas[0].width
        x = 0
      else
        x = ($scope.canvas[0].width - width)/2
      if height == $scope.canvas[0].height
        y = 0
      else
        y = ($scope.canvas[0].height - height)/2
      # display image
      ctx.drawImage(photo, x, y, width, height)

    onMouseWheel = (e) ->
      e.preventDefault()
      if e.originalEvent.deltaY > 0
        $scope.zoomOut()
      else
        $scope.zoomIn()

    onMouseDown = (e) ->
      e.preventDefault()
      dradding = true

    onMouseUp = (e) ->
      e.preventDefault()
      dradding = false

    onMouseMove = (e) ->
      e.preventDefault()
      if not dradding
        return
      if e.originalEvent.movementX?
        $scope.goUp(e.originalEvent.movementY)
        $scope.goLeft(e.originalEvent.movementX)
      else if e.originalEvent.mozMovementX?
        $scope.goUp(e.originalEvent.mozMovementY)
        $scope.goLeft(e.originalEvent.mozMovementX)

    $scope.displayPhoto = (file) ->
      reader.readAsDataURL(file)

    $scope.displaySnap = ->
      videoWidth = $scope.file.videoWidth
      videoHeight = $scope.file.videoHeight
      ratio = videoHeight / videoWidth
      # compute new size image
      if ratio < $scope.canvas[0].height / $scope.canvas[0].width
        width = $scope.canvas[0].width
        height = width * ratio
      else
        height = $scope.canvas[0].height
        width = height / ratio
      # display picture
      ctx.drawImage($scope.file, 0, 0, width, height)
      photo.src = $scope.canvas[0].toDataURL()

    $scope.zoomIn = (pixels = 10) ->
      ctx.clearRect(0, 0, $scope.canvas[0].width, $scope.canvas[0].height)
      width += 2*pixels
      height = width * ratio
      x -= pixels
      y -= pixels * ratio
      ctx.drawImage(photo, x, y, width, height)

    $scope.zoomOut = (pixels = 10) ->
      ctx.clearRect(0, 0, $scope.canvas[0].width, $scope.canvas[0].height)
      width -= 2*pixels
      height = width * ratio
      x += pixels
      y += pixels * ratio
      ctx.drawImage(photo, x, y, width, height)

    $scope.goUp = (pixels = 10) ->
      ctx.clearRect(0, 0, $scope.canvas[0].width, $scope.canvas[0].height)
      y += pixels
      ctx.drawImage(photo, x, y, width, height)

    $scope.goDown = (pixels = 10) ->
      ctx.clearRect(0, 0, $scope.canvas[0].width, $scope.canvas[0].height)
      y -= pixels
      ctx.drawImage(photo, x, y, width, height)

    $scope.goLeft = (pixels = 10) ->
      ctx.clearRect(0, 0, $scope.canvas[0].width, $scope.canvas[0].height)
      x += pixels
      ctx.drawImage(photo, x, y, width, height)

    $scope.goRight = (pixels = 10) ->
      ctx.clearRect(0, 0, $scope.canvas[0].width, $scope.canvas[0].height)
      x -= pixels
      ctx.drawImage(photo, x, y, width, height)

    $scope.validate = ->
      dataURL = $scope.canvas[0].toDataURL()
      frontier = dataURL.search(',')
      shortDataUrl = dataURL.substr(frontier+1)
      decoded = atob(shortDataUrl)
      length = decoded.length
      ab = new ArrayBuffer(length)
      ua = new Uint8Array(ab)
      for i in [0..length-1]
        ua[i] = decoded.charCodeAt(i)
      fd = new FormData()
      blob = new Blob([ua], {type: 'image/png'})
      name = $scope.file.name
      if name?
        name = name.substr(0, name.lastIndexOf(".")) + ".png"
      else
        name = "test.png"
      fd.append("file", blob, name)
      params =
        withCredentials: true
        headers:
          'Content-Type': undefined
          Authorization: sessionTools.getAuthorizationHeader()
      $http.post(SETTINGS.API_URL + '/fichiers', fd, params)
        .success (file) ->
          $scope.generatedFile = file
        .error (error) ->
          console.log(error)
