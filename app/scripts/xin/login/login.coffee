'use strict'


angular.module('xin.login', ['ngRoute', 'ngCookies',
                             'xin.session', 'app.settings', 'app.views.login.modal'])

  .factory 'updatePreferenceCurrentHabilitation', ($q, $modal, session, sessionTools) ->
    ->
      session.getUserPromise().then (user) ->
        # If user has multiple accreditations, it must have chosen one of them
        # as current in it preferences.
        # Otherwise (or if the selected accreditation is now invalid) we have
        # to make him select a new one and update it preferences accordingly.
        current_accrediation_id = user.preferences?.current_accreditation_id
        current_accr = user.accreditations[current_accrediation_id]
        if user.accreditations.filter(sessionTools.isValidAccreditation).length < 2
          # No need to select an accreditation
          return $q.when()  # TODO: use `$q.resolve()` when switching to angular>=1.4.14
        if current_accr? and sessionTools.isValidAccreditation(current_accr)
          # Selected accreditation is valid
          return $q.when()  # TODO: use `$q.resolve()` when switching to angular>=1.4.14
        # No or invalid preference set, show habilitation pop-up
        modalInstance = $modal.open(
          templateUrl: 'scripts/xin/habilitations/modal/change_habilitations.html'
          controller: 'modalHabilitationsController'
          backdrop: false
          keyboard: false
          resolve:
            message: ->
              return "Veuillez sélectionner une habilitation"
            alert_displayed: ->
              return false
            cancel_displayed: ->
              return false
        )
        return modalInstance.result

  .controller 'LoginController', ($scope, $location, $route, $http, $modal, $cookies,
                                  session, SETTINGS, updatePreferenceCurrentHabilitation) ->
      # Basic login stuff : User post a form to get the token
      $scope.basicLogin =
        login: undefined
        password: undefined
        remember_me: false

      # Try to use the remember-me each time the login is required
      # $scope.$on 'event:auth-loginRequired', (rejection, data) ->
      #   if not (data._errors? and data._errors[0]? and data._errors[0] == "Token frais requis")
      #     session.rememberMeLogin()

      # Try to use cookies each time the login is required
      $scope.$on 'event:auth-loginRequired', (rejection, data) ->
        $scope.basicLogin.login = $cookies.get("basicLogin_login")
        if $scope.basicLogin.login? and $scope.basicLogin.login != ""
          $scope.basicLogin.remember_me = true

      $scope.basicLoginProceed = ->
        if (not $scope.basicLoginForm.$valid or
            not $scope.basicLoginForm.$dirty)
          return
        remember_me = $scope.basicLogin.remember_me
        $scope.basicLogin.remember_me = false
        if not remember_me
          $cookies.remove("basicLogin_login")
        $http(
          method: 'POST'
          url: SETTINGS.API_URL + "/agent/login"
          data: $scope.basicLogin
          ignoreAuthModule: true
        )
          .success (data, status, headers, config) ->
            # up to date cookie
            if remember_me
              $cookies.put("basicLogin_login", $scope.basicLogin.login)
            session.login(data.token, data.remember_me_token)
          .error (data, status, headers, config) ->
            if status == 401 and data? and Object.keys(data).length
              modalInstance = $modal.open(
                templateUrl: 'scripts/xin/login/modal/change_pwd.html'
                controller: 'ModalInstanceChangeExpiredPWDController'
                resolve:
                  email: ->
                    return $scope.basicLogin.login
              )
              modalInstance.result.then(
                (token) ->
                  session.login(token, false)
              )
            else
              $scope.basicLoginFailed = true

      $scope.recoveryPWD = ->
        modalInstance = $modal.open(
          templateUrl: 'scripts/xin/login/modal/recovery_pwd.html'
          controller: 'ModalInstanceRecoveryPWDController'
        )

      # Token login : Oauth redirection call the route with a token param
      # If a token is provided by the request, proceed to the login
      routeParams = angular.copy($route.current.params)

      if routeParams.token?
        session.login(routeParams.token)
        # Remove token in params to clean a bit
        $location.search('token', null).replace()

      if (routeParams.email? and routeParams.token?)
        $location.search('token', null).replace()
        $location.search('email', null).replace()
        modalInstance = $modal.open(
          templateUrl: 'scripts/xin/login/modal/change_pwd.html'
          controller: 'ModalInstanceChangePWDController'
          resolve:
            token: ->
              return routeParams.token
            email: ->
              return routeParams.email
        )



  .directive 'loginDirective', (session) ->
    restrict: 'E'
    controller: "LoginController"
    templateUrl: 'scripts/xin/login/login.html'
    link: (scope, elem, attrs) ->
      if session.isLogged
        elem.hide()
      scope.$on 'event:auth-loginConfirmed', ->
        elem.hide()
      scope.$on 'event:auth-loginRequired', ->
        elem.show()


  .directive 'contentDirective', (session, updatePreferenceCurrentHabilitation) ->
    restrict: 'E'
    link: (scope, elem, attrs) ->
      scope.habilitationChoosedManually = false
      scope.habilitationChoosedAutomatically = false
      if not session.isLogged
        elem.hide()
      scope.$on 'event:auth-loginRequired', ->
        elem.hide()
      scope.$on 'event:auth-loginConfirmed', ->
        updatePreferenceCurrentHabilitation().then ->
          elem.show()
