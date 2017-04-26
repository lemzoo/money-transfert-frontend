'use strict'


angular.module('xin.solr_filter.modal', [])

  .controller 'ModalInstanceInformationController', ($scope, $modalInstance) ->
    $scope.cancel = ->
      $modalInstance.dismiss('cancel')
