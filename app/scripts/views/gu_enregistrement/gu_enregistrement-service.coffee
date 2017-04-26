"use strict"

angular.module("app.views.gu_enregistrement_service", [])
  .factory "init_usager_for_recueil", () ->
    (recueil_statut, type_usager, usager = {}) ->
      if type_usager == "usager1"
        usager.active = true
      else
        if Object.keys(usager).length
          usager.active = true
        else
          usager.active = false
      if recueil_statut == "DEMANDEURS_IDENTIFIES" and not usager.demandeur?
        usager.demandeur = false
      usager.langues_audition_OFPRA = usager.langues_audition_OFPRA or []
      usager.langues = usager.langues or []
      usager.prenoms = usager.prenoms or []
      usager.nationalites = usager.nationalites or []
      usager.vulnerabilite = usager.vulnerabilite or {'mobilite_reduite': false}
      if recueil_statut in ["DEMANDEURS_IDENTIFIES", "EXPLOITE"]
        if usager.type_demande?
          if usager.type_demande in ["PREMIERE_DEMANDE_ASILE", "REOUVERTURE_DOSSIER"]
            usager.decision_sur_attestation = true
          else
            usager.type_procedure = "ACCELEREE"
            usager.motif_qualification_procedure = "REEX"
            if parseInt(usager.numero_reexamen) == 1
              usager.decision_sur_attestation = true
            else
              usager.decision_sur_attestation = false
              usager.refus =
                motif: "DEUXIEME_DEMANDE_REEXAMEN"
                date_notification: moment()._d
      return usager


  .factory "clean_usager_to_save", () ->
    (usager) ->
      cleanFiles = (files) ->
        cleaned_files = []
        for file in files or []
          if file.id?
            cleaned_files.push(file.id)
        return cleaned_files
      usager_r = {}
      angular.copy(usager, usager_r)
      delete usager_r.active
      if usager_r.pays_naissance == ''
        delete usager_r.pays_naissance
      if usager_r.origine_nom == ''
        delete usager_r.origine_nom
      if usager_r.origine_nom_usage == ''
        delete usager_r.origine_nom_usage
      if usager_r.demandeur
        if usager_r.type_demande != "REEXAMEN"
          delete usager_r.numero_reexamen
      else
        delete usager_r.type_demande
        delete usager_r.numero_reexamen
      if usager_r.photo?
        if usager_r.photo.id?
          usager_r.photo = usager_r.photo.id
        else
          delete usager_r.photo
      usager_r.documents = cleanFiles(usager_r.documents)
      return usager_r


  .factory "bindUsagerExistant", (bindUsagerExistantIds) ->
    (usager_src, usager_dest) ->
      bindUsagerExistantIds(usager_src, usager_dest)
      usager_dest.nom = usager_src.nom
      usager_dest.origine_nom = usager_src.origine_nom
      usager_dest.nom_usage = usager_src.nom_usage
      usager_dest.origine_nom_usage = usager_src.origine_nom_usage
      usager_dest.prenoms = usager_src.prenoms
      usager_dest.photo = usager_src.photo
      usager_dest.sexe = usager_src.sexe
      usager_dest.ecv_valide = usager_src.ecv_valide
      usager_dest.date_naissance = moment(usager_src.date_naissance)
      usager_dest.date_naissance_approximative = usager_src.date_naissance_approximative
      usager_dest.pays_naissance = usager_src.pays_naissance
      usager_dest.ville_naissance = usager_src.ville_naissance
      usager_dest.nationalites = usager_src.nationalites or []
      usager_dest.nom_pere = usager_src.nom_pere
      usager_dest.prenom_pere = usager_src.prenom_pere
      usager_dest.nom_mere = usager_src.nom_mere
      usager_dest.prenom_mere = usager_src.prenom_mere
      usager_dest.situation_familiale = usager_src.situation_familiale
      if usager_src.representant_legal_nom?
        usager_dest.representant_legal_nom = usager_src.representant_legal_nom
      if usager_src.representant_legal_prenom?
        usager_dest.representant_legal_prenom = usager_src.representant_legal_prenom
      if usager_src.representant_legal_personne_morale?
        usager_dest.representant_legal_personne_morale = usager_src.representant_legal_personne_morale
      if usager_src.representant_legal_personne_morale_designation?
        usager_dest.representant_legal_personne_morale_designation = usager_src.representant_legal_personne_morale_designation
      usager_dest.telephone = usager_src.telephone
      usager_dest.email = usager_src.email
      usager_dest.adresse = usager_src.localisation.adresse
      usager_dest.langues = usager_src.langues or []
      usager_dest.langues_audition_OFPRA = usager_src.langues_audition_OFPRA or []


  .factory "bindUsagerExistantIds", () ->
    (usager_src, usager_dest) ->
      usager_dest.identifiant_agdref = usager_src.identifiant_agdref
      usager_dest.identifiants_eurodac = usager_src.identifiants_eurodac
