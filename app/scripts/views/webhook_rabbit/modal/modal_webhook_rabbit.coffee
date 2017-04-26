'use strict'


angular.module('app.views.webhook_rabbit.modal', [])
  .controller 'ModalInstancePatchMessageController', ($scope, $modalInstance, msg_id, context) ->
    $scope.msg_id = msg_id
    $scope.context = context
    $scope.patch = ->
      $modalInstance.close($scope.context)
    $scope.cancel = ->
      $modalInstance.dismiss('cancel')

  .controller 'ModalInstanceExcludedMessagesController', ($scope, $modalInstance, excludedMessages) ->
    $scope.excludedMessages = excludedMessages
    $scope.ok = ->
      $modalInstance.close(true)
