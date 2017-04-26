'use strict'


getAuthorizationHeader = ->
  token = sessionStorage.getItem('token')
  if token?
    return "Token #{token}"
  else
    return undefined


_currentAccreditationId = undefined
getUseAccreditationHeader = ->
  if _currentAccreditationId?
    return "#{_currentAccreditationId}"
  else
    return ''


isValidAccreditation = (accr) -> (not accr.fin_validite? or new Date(accr.fin_validite).getTime() > new Date().getTime())
getAccreditation = (accreditations, target_id) ->
  for accr in accreditations
    if accr.id == target_id
      return accr
  return undefined


angular.module('xin.session', ['http-auth-interceptor', 'xin.storage', 'xin.backend', 'app.settings'])
  .factory 'session', ($http, $window, $q, authService, SETTINGS, localStorage, sessionStorage, Backend) ->
    # Monitor remember_me_token for cross tab evens
    sessionStorage.addEventListener (e) ->
      if e.key == 'remember_me_token'
        if e.newValue
          # New remember-me token, reload the page to use this one
          $window.location.reload()
        else
          # logout from another tab (i.e. remember-me destroyed), logout ourself
          Session.logout()
    class Session
      @isLogged = -> sessionStorage.getItem('token')?
      @_userPromise = undefined
      @updateUserPromise = =>
        # Force the cache to really get current user
        @_userPromise = Backend.one('moi').get(
          {},
          {'Cache-Control': 'no-cache'}
        ).then (user) ->
          # If current accreditation has been specified in preferences and is
          # still valid, we have to pass it to the X-Use-Accreditation header
          if user.preferences?.current_accreditation_id?
            currId = user.preferences?.current_accreditation_id
            # user has been retreived with the first available accreditation given
            # we didn't provide an X-Use-Accreditation header. Now we have to patch the
            # `current_*` fields to use be coherent with the accreditation
            # selected in preferences.
            current_accr = getAccreditation(user.accreditations, currId)
            if current_accr is undefined
              throw "Bad accreditation id #{currId} from preferences."
            if isValidAccreditation(current_accr)
              _currentAccreditationId = currId
              user.current_accreditation_id = currId
          # Patch user to provide it with current accreditation's fields
          current_accr = getAccreditation(user.accreditations, user.current_accreditation_id)
          user.role = current_accr.role
          user.site_affecte = current_accr.site_affecte
          user.site_rattache = current_accr.site_rattache
          return user
      @can = (permission) =>
        defer = $q.defer()
        @getUserPromise().then (user) ->
          if (SETTINGS.PERMISSIONS[user.role]? and
              permission in SETTINGS.PERMISSIONS[user.role])
            defer.resolve()
          else
            defer.reject()
        return defer.promise
      @getUserPromise = =>
        defer = $q.defer()
        if not @_userPromise?
          @updateUserPromise()
        @_userPromise.then (user) -> defer.resolve(user)
        return defer.promise
      @rememberMeLogin = =>
        remember_me_token = localStorage.getItem("remember_me_token")
        if not remember_me_token
          return false # No remember-me available
        $http.post(SETTINGS.API_URL + "/agent/login/remember-me", {'remember_me_token': remember_me_token}, {ignoreAuthModule: true})
          .success (data, status, headers, config) ->
            Session.login(data.token)
          .error (data, status, headers, config) ->
            localStorage.removeItem('remember_me_token')
            throw "remember-me login failed : #{status}, #{data}"
        return true # Remember-me login
      @login = (token, remember_me_token) ->
        sessionStorage.setItem("token", token)
        if remember_me_token?
          localStorage.setItem("remember_me_token", remember_me_token)
        authService.loginConfirmed undefined, (config) ->
          # Update $http config
          config.headers["Authorization"] = getAuthorizationHeader()
          config.headers["X-Use-Accreditation"] = getUseAccreditationHeader()
          return config
      @logout: ->
        localStorage.removeItem('remember_me_token')
        sessionStorage.removeItem('token')
        $window.location.assign('/')


angular.module('xin.sessionTools', ['xin.storage'])
  .factory 'sessionTools', ->
    class sessionTools
      @getAuthorizationHeader: getAuthorizationHeader
      @getUseAccreditationHeader: getUseAccreditationHeader
      @isValidAccreditation = isValidAccreditation
