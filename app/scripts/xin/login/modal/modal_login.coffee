'use strict'

angular.module('app.views.login.modal', ['ngRoute', 'xin.backend', 'xin.form'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/reset/:email/:token',
        redirectTo: '/accueil'


  .controller 'ModalInstanceRecoveryPWDController', ($scope, $modalInstance, Backend) ->
    $scope.pwdGenerated = false
    $scope.email = ''

    $scope.setPWD = ->
      if ($scope.recoveryPWDForm.$valid and $scope.recoveryPWDForm.$dirty)
        $scope.pwdGenerated = true
        Backend.one("/agent/login/password_recovery/#{$scope.email}").get()

    $scope.cancel = ->
      $modalInstance.dismiss('cancel')



  .controller 'ModalInstanceChangePWDController', ($scope, $modalInstance, $http, Backend, SETTINGS, token, email) ->
    $scope.token = token
    $scope.email = email
    $scope.etat = "form"
    $scope.password = ''
    $scope.confirm_password = ''

    $scope.cancel = ->
      $modalInstance.dismiss('cancel')

    $scope.updatePWD = ->
      $scope._errors = {}
      if $scope.password != $scope.confirm_password
        $scope._errors.confirm_password = "Les mots de passe sont différents."
      else
        $http(
          method: 'POST'
          url: SETTINGS.API_URL + "/agent/login/password_recovery/" + $scope.email
          ignoreAuthModule: true
          data:
            password: $scope.password,
            token: $scope.token
        )
          .success (data, status, headers, config) ->
            $scope.etat = "success"
          .error (data, status, headers, config) ->
            error =
              status: status
              data: data
            manageErrors(error)

    manageErrors = (errors) ->
      if errors.status == 200
        $scope.etat = "success"
      else if (errors.status == 401)
        $scope._errors.general =  errors.data._errors[0].password
      else if (errors.status == 409)
        $scope._errors.general =  errors.data._errors[0]
      else
        $scope._errors.general = "Une erreur inattendue s'est produite. Merci de contacter votre administrateur."



  .controller 'ModalInstanceChangeExpiredPWDController', ($scope, $modalInstance, $http, SETTINGS, email) ->
    $scope.expired = true
    $scope.etat = "form"
    $scope.email = email
    $scope.old_password = ''
    $scope.password = ''
    $scope.confirm_password = ''
    $scope.token = ''

    $scope.cancel = ->
      if ($scope.token?)
        $modalInstance.close($scope.token)
      else
        $modalInstance.dismiss('cancel')

    $scope.updatePWD = ->
      $scope._errors = {}

      if $scope.password != $scope.confirm_password
        $scope._errors.confirm_password = "Les mots de passe sont différents."
      else
        $http(
          method: 'POST'
          url: SETTINGS.API_URL + "/agent/login/password"
          ignoreAuthModule: true
          data:
            login: $scope.email,
            password: $scope.old_password,
            new_password: $scope.password
        )
          .success (data, status, headers, config) ->
            $scope.etat = "success"
            $scope.token = data.token
          .error (data, status, headers, config) ->
            error =
              status: status
              data: data
            manageErrors(error)

    manageErrors = (errors) ->
      if errors.status == 200
        $scope.etat = "success"
      else if errors.status == 401
        $scope._errors.general = "Le mot de passe actuel est incorrect."
      else if (errors.status == 409)
        $scope._errors.general = errors.data._errors[0]
      else
        $scope._errors.general = "Une erreur inattendue s'est produite. Merci de contacter votre administrateur."
