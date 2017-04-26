'use strict'


angular.module('xin.backend', ['ngRoute', 'restangular', 'xin.sessionTools', 'xin.testBackendConnexion'])
  .factory 'Backend', ($location, Restangular, sessionTools, SETTINGS, backendConnexion) ->
    backendConfig = Restangular.withConfig (RestangularConfigurer) ->
      # Correct the url built by restangular if the API_URL_PREFIX was missing
      default_base = RestangularConfigurer.urlCreatorFactory.path.prototype.base
      RestangularConfigurer.urlCreatorFactory.path.prototype.base = (current) ->
        if SETTINGS.API_URL_PREFIX == ""
          return default_base.apply(this, [current])
        base_url = this.config.baseUrl
        this.config.baseUrl = ''
        url = default_base.apply(this, [current])
        this.config.baseUrl = base_url
        if url.startsWith(SETTINGS.API_URL_PREFIX)
          url = url.substr(SETTINGS.API_URL_PREFIX.length)
        return base_url + url
      RestangularConfigurer.setDefaultHeaders
          Authorization: sessionTools.getAuthorizationHeader
          'Cache-Control': -> 'no-cache'
        .setRestangularFields
          etag: "_etag"
        .addFullRequestInterceptor (element, operation, route, url, headers, params, httpConfig) ->
          # Cannot set X-Use-Accreditations in `setDefaultHeaders` given it will be
          # defined after the first restangular request (i.e. the GET /moi)
          headers['X-Use-Accreditation'] = sessionTools.getUseAccreditationHeader()
          return {
            element: element,
            params: params,
            headers: headers,
            httpConfig: httpConfig
          }
        .addResponseInterceptor (data, operation, what, url, response, deferred) ->
          if operation == "getList"
            extractedData = data._items
            extractedData._meta = data._meta
            extractedData._links = data._links
            extractedData.self = data.self
          else
            extractedData = data
          return extractedData
        .setErrorInterceptor (response, deferred, responseHandler) ->
          backendConnexion.setStatus(response.status)
          if response.status == 404
            $location.path('/404')
          else if response.status == 403
            $location.path('/403')
          else
            return true # error not handled
          return false # error handled



  .factory 'BackendWithoutInterceptor', ($location, Restangular, sessionTools, SETTINGS, backendConnexion) ->
    backendConfig = Restangular.withConfig (RestangularConfigurer) ->
      # Correct the url built by restangular if the API_URL_PREFIX was missing
      default_base = RestangularConfigurer.urlCreatorFactory.path.prototype.base
      RestangularConfigurer.urlCreatorFactory.path.prototype.base = (current) ->
        if SETTINGS.API_URL_PREFIX == ""
          return default_base.apply(this, [current])
        base_url = this.config.baseUrl
        this.config.baseUrl = ''
        url = default_base.apply(this, [current])
        this.config.baseUrl = base_url
        if url.startsWith(SETTINGS.API_URL_PREFIX)
          url = url.substr(SETTINGS.API_URL_PREFIX.length)
        return base_url + url
      RestangularConfigurer.setDefaultHeaders
          Authorization: sessionTools.getAuthorizationHeader
          'X-Use-Accreditation': sessionTools.getUseAccreditationHeader
          'Cache-Control': -> 'no-cache'
        .setRestangularFields
          etag: "_etag"
        .addResponseInterceptor (data, operation, what, url, response, deferred) ->
          if operation == "getList"
            extractedData = data._items
            extractedData._meta = data._meta
            extractedData._links = data._links
            extractedData.self = data.self
          else
            extractedData = data
          return extractedData
