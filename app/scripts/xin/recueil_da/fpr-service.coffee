"use strict"

angular.module('xin.fpr_service', ["xin.backend"])
  .factory 'getUsagerFpr', ($q, Backend) ->
    (usager) ->
      defer = $q.defer()
      result =
        has_fpr_usagers: false
        no_fpr: false
        fpr_usagers: null

      date_naissance = if usager.date_naissance? then usager.date_naissance else ''
      nom = usager.nom or ''
      prenoms = ''
      for prenom in usager.prenoms or []
        prenoms += " " + prenom
      prenoms = prenoms.trim()
      if nom == '' or date_naissance == '' or prenoms == ''
        defer.reject()
        return defer.promise

      r_prenom = 'prenom='+prenoms.substring(0, 25)
      r_nom = 'nom='+nom
      date_naissance_m = moment(date_naissance).utc()
      r_date_naissance = 'date_naissance='+date_naissance_m.format('YYYYMMDD')
      r_params = "#{r_prenom}&#{r_nom}&#{r_date_naissance}"

      Backend.one("recherche_fpr?#{r_params}").get().then(
        (fpr_result) ->
          if fpr_result.resultat.resultat
            result.has_fpr_usagers = true
          result.fpr_usagers = fpr_result
          result.fpr_usagers.date_naissance = moment(result.fpr_usagers.date_naissance, "YYYYMMDD")
          defer.resolve(result)
        (error) ->
          result.no_fpr = true
          defer.resolve(result)
      )
      return defer.promise
