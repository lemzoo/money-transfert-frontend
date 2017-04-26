'use strict'


angular.module('app.views.utilisateur.modal', [])
  .controller 'ModalInstanceEditPasswordController', ($scope, $modalInstance, $http, SETTINGS, Backend,
                                                      session, ownProfil, utilisateur) ->
    $scope.etat = "form"
    $scope.oldPassword = ''
    $scope.password = ''
    $scope.confirm_password = ''
    $scope.ownProfil = ownProfil
    token = ""

    $scope.ok = ->
      $scope._errors = {}
      if $scope.password != $scope.confirm_password
        $scope._errors.confirm_password = "Les mots de passe sont différents."
        return
      if ownProfil
        session.getUserPromise().then (user) ->
          $http(
            method: 'POST'
            url: SETTINGS.API_URL + "/agent/login/password"
            ignoreAuthModule: true
            headers:
              'if-match': utilisateur._version
            data:
              login: user.email
              password: $scope.oldPassword
              new_password: $scope.password
          )
            .success (data, status, headers, config) ->
              token = data.token
              $scope.etat = "success"
            .error (data, status, headers, config) ->
              error =
                status: status
                data: data
              manageErrors(error)
      else
        Backend.one("utilisateurs/#{utilisateur.id}").patch({password: $scope.password}, null, {'if-match': utilisateur._version}).then(
          (result) ->
            $scope.etat = "success"
          (error) ->
            manageErrors(error)
        )

    manageErrors = (errors) ->
      if errors.status == 412
        $scope._errors.general = "Echec de la modification du mot de passe. Le document a été modifié par un autre utilisateur entre-temps."
      else if errors.status == 401
        $scope._errors.oldPassword = "Mot de passe incorrect."
      else if errors.status == 400
        $scope._errors.password = errors.data._errors[0]
      else if errors.status == 409
        $scope._errors.password = errors.data._errors[0]
      else
        $scope._errors.general = "Une erreur inattendue s'est produite. Merci de contacter votre administrateur."

    $scope.success = ->
      $modalInstance.close(token)

    $scope.cancel = ->
      $modalInstance.close(false)


  .controller 'ModalInstanceUserCreatedController', ($scope, $modalInstance, user) ->
    $scope.user = user
    $scope.listUsers = ->
      $modalInstance.close('list')
    $scope.showUser = ->
      $modalInstance.close('show')


  .controller 'ModalInstanceDeactivateController', ($scope, $modalInstance) ->
    now = moment().startOf('day')
    $scope.fin_validite = new Date()
    $scope._error = undefined

    $scope.$watch 'fin_validite', (value) ->
      if value? and moment(value) >= now
        delete $scope._error
      else
        $scope._error = "Veuillez sélectionner une date égale ou postérieure à la date du jour (#{now.format('DD/MM/YYYY')})"

    $scope.ok = ->
      $modalInstance.close($scope.fin_validite)
    $scope.cancel = ->
      $modalInstance.close(false)
