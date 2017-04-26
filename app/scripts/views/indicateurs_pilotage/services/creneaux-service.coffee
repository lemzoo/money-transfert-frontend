"use strict"

angular.module('app.views.indicateurs.creneaux_service', ['app.settings',
                                                          'xin.session', 'xin.backend',
                                                          'app.views.indicateurs.common_service'])
  .service 'get_creneaux_ouverts', ($q, make_group_queries,
                                    query_creneaux_ouverts,
                                    query_creneaux_deleted) ->
    (gus, date) ->
      defer = $q.defer()
      promises = []
      result = {}
      facet_query = "facet=true"
      group_queries = make_group_queries(gus)
      for group_query in group_queries
        url = "analytics?fq=doc_type:rendez_vous_ouvert&fq=date_creneau_dt:#{date}&#{group_query}"
        promises.push(query_creneaux_ouverts(url, result))
      $q.all(promises).then(
        () ->
          promise = []
          for group_query in group_queries
            url = "analytics?fq=doc_type:rendez_vous_supprime&fq=date_creneau_dt:#{date}&#{group_query}"
            promises.push(query_creneaux_deleted(url, result))
          $q.all(promises).then(
            () -> defer.resolve(result)
          )
      )
      return defer.promise

  .service 'query_creneaux_ouverts', ($q, Backend, parse_response) ->
    (url, target) ->
      defer = $q.defer()
      Backend.one(url).get().then(
        (response) ->
          result = parse_response(JSON.parse(response))
          for key, index of result
            target[key] = index
          defer.resolve()
        (error) -> defer.resolve()
      )
      return defer.promise

  .service 'query_creneaux_deleted', ($q, Backend, parse_response) ->
    (url, target) ->
      defer = $q.defer()
      Backend.one(url).get().then(
        (response) ->
          result = parse_response(JSON.parse(response))
          for key, index of result
            target[key] -= index
          defer.resolve()
        (error) -> defer.resolve()
      )
      return defer.promise
