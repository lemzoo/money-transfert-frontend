"use strict"

angular.module('app.views.indicateurs.common_service', ['app.settings',
                                                        'xin.session', 'xin.backend'])
  .service 'make_group_queries', () ->
    (gus) ->
      nb_site_by_request = 5
      group_queries = []
      group_query = "group=true"
      site_filter = ""
      index = 0
      while index < gus.length
        group_query += "&group.query=guichet_unique_s:#{gus[index].id}"
        if site_filter != ""
          site_filter += " OR #{gus[index].id}"
        else
          site_filter += "#{gus[index].id}"
        index = index + 1
        if index % nb_site_by_request is 0
          group_queries.push(group_query)
          group_query = "group=true"
          site_filter = ""
      if index % nb_site_by_request isnt 0
        group_queries.push(group_query)
      return group_queries

  .service 'parse_response', () ->
    (response_parse) ->
      gus = {}
      for key, group of response_parse.grouped
        key = key.split(":")
        type_site = key[0]
        id = key[1]
        if type_site == "guichet_unique_s"
          gus[id] = group.doclist.numFound
      return gus
