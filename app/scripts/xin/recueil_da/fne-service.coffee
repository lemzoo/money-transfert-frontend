"use strict"

angular.module('xin.fne_service', ["xin.backend"])
  .factory 'checkPatronymePattern', () ->
    (str) ->
      low = "abcdefghijklmnopqrstuvwxyzáàâäåãæçéèêëíìîïñóòôöõøœšúùûüýÿž"
      up = low.toUpperCase()
      spe = " \-"
      final_regex = RegExp("^([" + up + "]|([" + up + "][" + up + low + spe + "]*[" + up + low + spe + "]))$")
      return final_regex.test(str)


  .factory 'getUsagersFne', ($q, BackendWithoutInterceptor, checkPatronymePattern) ->
    (usager) ->
      defer = $q.defer()
      if not usager?
        defer.reject()
        return defer.promise

      nom = usager.nom or ''
      prenoms = ''
      for prenom in usager.prenoms or []
        prenoms += prenom + ' '
      prenoms = prenoms.trim()
      date_naissance = usager.date_naissance or ''
      sexe = usager.sexe or ''
      if nom == '' or prenoms == '' or sexe == '' or
         !checkPatronymePattern(nom) or !checkPatronymePattern(prenoms)
        defer.reject()
        return defer.promise

      result =
        fne_cr206: false
        no_fne: false
        pf_usagers: []
        fne_usagers: []

      r_nom = '&nom='+nom
      r_prenom = '&prenom='+prenoms
      date_naissance_m = moment(date_naissance).utc()
      r_date_naissance = '&date_naissance='+date_naissance_m.format('YYYY-MM-DD')
      r_sexe = '&sexe='+sexe
      r_params = r_nom + r_prenom + r_sexe + r_date_naissance
      BackendWithoutInterceptor.one('/recherche_usagers_tiers?' + r_params).get().then(
        (items) ->
          if items['PLATEFORME']
            result.pf_usagers = items['PLATEFORME']

          if items['FNE']?
            if items['FNE'].usagers? and items['FNE'].usagers.length > 0
              for fne_usager in items['FNE'].usagers when fne_usager != usager.identifiant_agdref
                result.fne_usagers.push(fne_usager)

            if items['FNE'].errors?
              for error in items['FNE'].errors
                if error.code == 416
                  result.fne_cr206 = true
                else
                  result.no_fne = true
          defer.resolve(result)

        (errors) ->
          result.no_fne = true
          defer.resolve(result)
      )
      return defer.promise


  .factory 'retrieveFneUsager', ($q, BackendWithoutInterceptor) ->
    (identifiant_agdref) ->
      defer = $q.defer()
      fne_usager = null
      BackendWithoutInterceptor.one("/recherche_usagers_tiers/usager?identifiant_agdref=#{identifiant_agdref}").get().then(
        (usager) ->
          if usager.nationalite
            usager.nationalites = []
            BackendWithoutInterceptor.one("/referentiels/nationalites/#{usager.nationalite}").get().then(
              (referentiel) ->
                usager.nationalites.push({code: usager.nationalite, libelle: referentiel.libelle})
                usager.nationalite = undefined
              (error) ->
                usager.nationalite = undefined
            )
          if usager.pays_naissance
            BackendWithoutInterceptor.one('/referentiels/pays/' + usager.pays_naissance).get().then(
              (pays) ->
                usager.pays_naissance =
                  'code': usager.pays_naissance
                  'libelle': pays.libelle
              (error) ->
                usager.pays_naissance = undefined
            )
          defer.resolve(usager)
        (error) -> defer.reject(error)
      )
      return defer.promise


  .factory 'bindUsagerFne', (bindUsagerFneIds) ->
    (fne_usager, usager) ->
      bindUsagerFneIds(fne_usager, usager)
      usager.nom = fne_usager.nom
      usager.origine_nom = fne_usager.origine_nom
      usager.nom_usage = fne_usager.nom_usage
      usager.origine_nom_usage = fne_usager.origine_nom_usage
      usager.prenoms = fne_usager.prenoms
      usager.sexe = fne_usager.sexe
      usager.date_naissance = fne_usager.date_naissance
      usager.date_naissance_approximative = fne_usager.date_naissance_approximative
      usager.pays_naissance = fne_usager.pays_naissance
      usager.ville_naissance = fne_usager.ville_naissance
      usager.nationalites = fne_usager.nationalites or []
      usager.nom_pere = fne_usager.nom_pere
      usager.prenom_pere = fne_usager.prenom_pere
      usager.nom_mere = fne_usager.nom_mere
      usager.prenom_mere = fne_usager.prenom_mere
      usager.situation_familiale = fne_usager.situation_familiale
      if fne_usager.representant_legal_nom?
        usager.representant_legal_nom = fne_usager.representant_legal_nom
      if fne_usager.representant_legal_prenom?
        usager.representant_legal_prenom = fne_usager.representant_legal_prenom
      if fne_usager.representant_legal_personne_morale?
        usager.representant_legal_personne_morale = fne_usager.representant_legal_personne_morale
      if fne_usager.representant_legal_personne_morale_designation?
        usager.representant_legal_personne_morale_designation = fne_usager.representant_legal_personne_morale_designation
      usager.telephone = fne_usager.telephone
      usager.email = fne_usager.email
      usager.adresse = fne_usager.localisations.adresse
      # Check if adresse_inconnue
      if usager.adresse.code_postal? and usager.adresse.code_postal == "00000"
        usager.adresse = { adresse_inconnue: true }
      else
        usager.adresse.adresse_inconnue = false
        # Clean fields
        delete(usager.adresse.codeVoie)
        for elt of usager.adresse
          if usager.adresse[elt] == '' or usager.adresse[elt] == null
            delete(usager.adresse[elt])
      usager.langues = fne_usager.langues or []
      usager.langues_audition_OFPRA = fne_usager.langues_audition_OFPRA or []


  .factory 'bindUsagerFneIds', () ->
    (fne_usager, usager) ->
      usager.identifiant_agdref = fne_usager.identifiant_agdref
      usager.identifiant_portail_agdref = fne_usager.identifiant_portail_agdref
