"use strict"


angular.module('app.views.gu_enregistrement.modal', [])
  .controller 'ModalInstanceGUConfirmSaveController', ($scope, $modalInstance, recueil_da, action_switch) ->
    $scope.recueil_da = recueil_da
    $scope.action_switch = action_switch

    $scope.ok = ->
      $modalInstance.close(true)
    $scope.cancel = ->
      $modalInstance.close(false)


  .controller 'ModalInstanceGURecueilSavedController', ($scope, $modalInstance, recueil_da, action_switch) ->
    $scope.recueil_da = recueil_da
    $scope.action_switch = action_switch
    $scope.listRecueils = ->
      $modalInstance.close('list')
    $scope.showRecueil = ->
      $modalInstance.close('show')


  .controller 'ModalInstanceGUEditRDVController', ($scope, $modalInstance, recueil_da) ->
    $scope.recueil_da = recueil_da
    $scope.listRecueils = ->
      $modalInstance.close('list')
    $scope.showRecueil = ->
      $modalInstance.close('show')
    $scope.showRdv = ->
      $modalInstance.close('rdv')


  .controller 'ModalHistoriqueDAController', ($scope, $modalInstance,
                                              Backend, SETTINGS, usager,
                                              retrieveFneUsager) ->
    $scope.usager = usager
    $scope.demandes_asile = []
    $scope.demande_en_cours = false
    $scope.recommendations =
      type_demande: "PREMIERE_DEMANDE_ASILE"
      numero_reexamen: ""
    $scope.origine_usager = "PORTAIL"
    $scope.DA_STATUT = SETTINGS.DA_STATUT
    $scope.DECISION_DEFINITIVE_NATURE = SETTINGS.DECISION_DEFINITIVE_NATURE
    $scope.TYPE_DEMANDE = {}
    for type in SETTINGS.TYPE_DEMANDE
      $scope.TYPE_DEMANDE[type.id] = type.libelle

    getUsagerFromFne = () ->
      retrieveFneUsager(usager.identifiant_agdref).then(
        (usager_fne) ->
          if usager_fne.indicateurPresenceDemandeAsile == 'O'
            $scope.origine_usager = "FNE"
            $scope.recommendations =
              type_demande: "REEXAMEN"
              numero_reexamen: 1
      )

    if usager.usager_existant?
      Backend.all("demandes_asile?fq=usager:#{usager.usager_existant.id}&sort=date_demande asc").getList().then(
        (demandes_asile) ->
          $scope.demandes_asile = demandes_asile.plain()
          if $scope.demandes_asile.length
            for da in $scope.demandes_asile
              if da.decisions_definitives?
                da.decision_definitive = da.decisions_definitives[da.decisions_definitives.length-1]
              else
                da.decision_definitive = null
            last_da = $scope.demandes_asile[$scope.demandes_asile.length-1]
            if last_da.statut in ["DECISION_DEFINITIVE", "FIN_PROCEDURE_DUBLIN", "FIN_PROCEDURE"]
              numero_reexamen = last_da.numero_reexamen or 0
              $scope.recommendations =
                type_demande: "REEXAMEN"
                numero_reexamen: numero_reexamen+1
            else
              $scope.demande_en_cours = true
          else
            getUsagerFromFne()
        (error) -> console.log(error)
      )
    else if usager.identifiant_agdref
      getUsagerFromFne()

    $scope.ok_and_apply = ->
      $modalInstance.close($scope.recommendations)
    $scope.ok_and_not_apply = ->
      $modalInstance.dismiss()
    $scope.cancel = ->
      $modalInstance.dismiss()


  .controller 'ModalInstanceFPRController', ($scope, $modalInstance, fpr_usagers) ->
    $scope.fpr_usagers = fpr_usagers
    $scope.cancel = ->
      $modalInstance.dismiss('cancel')


  .controller 'ModalSaveUsagerExistantController', ($scope, $modalInstance,
                                                    Backend, recueil_da, action_switch) ->
    $scope.post_recueil = "waiting"
    $scope.post_next_etat = "waiting"
    $scope.usagers = []

    addUsager = (resource, type_usager, index_enfant = 0) ->
      usager =
        resource: resource
        type: type_usager
        index_enfant: index_enfant
        patchAll: "waiting"
        patchEtatCivil: "waiting"
        patchMoreInformations: "waiting"
        patchAddress: "waiting"
      $scope.usagers.push(usager)

    if recueil_da.usager_1? and recueil_da.usager_1.usager_existant?
      addUsager(recueil_da.usager_1, "usager_1")
    if recueil_da.usager_2? and recueil_da.usager_2.usager_existant?
      addUsager(recueil_da.usager_2, "usager_2")
    for enfant, index in recueil_da.enfants or [] when enfant.usager_existant?
      addUsager(enfant, "enfant", index)

    nextUsager = (index) ->
      if $scope.usagers[index]?
        $scope.usagers[index].patchAll = "sending"
        patchEtatCivil(index)
      else
        if action_switch == "new"
          postRecueil()
        else
          putRecueil()

    makePayloadEtatCivil = (usager) ->
      fields = ["nom", "nom_usage", "prenoms", "photo", "sexe",
                "date_naissance", "date_naissance_approximative",
                "ville_naissance", "pays_naissance",
                "nationalites", "situation_familiale"]
      payload = {}
      for field in fields
        payload[field] = usager[field] or null
      return payload

    patchEtatCivil = (index) ->
      usager = $scope.usagers[index]
      if usager.resource.ecv_valide == true
        usager.patchEtatCivil = "success"
        patchUsager(index)
      else
        usager.patchEtatCivil = "sending"
        payload = makePayloadEtatCivil(usager.resource)
        Backend.all("usagers/#{usager.resource.usager_existant.id}/etat_civil")
          .patch(payload, null, {'if-match': usager.resource.usager_existant._version}).then(
            (usagerResource) ->
              usager.resource.usager_existant._version = usagerResource._version
              if usager.type in ["usager_1", "usager_2"]
                recueil_da[usager.type].usager_existant._version = usagerResource._version
              else
                recueil_da.enfants[index_enfant].usager_existant._version = usagerResource._version
              usager.patchEtatCivil = "success"
              patchUsager(index)
            (error) ->
              usager.patchEtatCivil = "failure"
              usager.patchAll = "failure"
              $modalInstance.close({success: false, errors: error, type_usager: usager.type, index_enfant: usager.index_enfant})
          )

    makePayload = (usager) ->
      fields = ["origine_nom", "origine_nom_usage", "nom_pere", "prenom_pere",
                "nom_mere", "prenom_mere", "langues",
                "representant_legal_nom", "representant_legal_prenom",
                "representant_legal_personne_morale", "representant_legal_personne_morale_designation",
                "telephone", "email", "date_deces"]
      fieldsNotNull = ["langues_audition_OFPRA"]
      payload = {}
      for field in fields
        payload[field] = usager[field] or null
      for field in fieldsNotNull
        payload[field] = usager[field] or undefined
      return payload

    patchUsager = (index) ->
      usager = $scope.usagers[index]
      usager.patchMoreInformations = "sending"
      payload = makePayload(usager.resource)
      Backend.all("usagers/#{usager.resource.usager_existant.id}")
        .patch(payload, null, {'if-match': usager.resource.usager_existant._version}).then(
          (usagerResource) ->
            usager.resource.usager_existant._version = usagerResource._version
            if usager.type in ["usager_1", "usager_2"]
              recueil_da[usager.type].usager_existant._version = usagerResource._version
            else
              recueil_da.enfants[index_enfant].usager_existant._version = usagerResource._version
            usager.patchMoreInformations = "success"
            patchAddress(index)
          (error) ->
            usager.patchMoreInformations = "failure"
            usager.patchAll = "failure"
            $modalInstance.close({success: false, errors: error, type_usager: usager.type, index_enfant: usager.index_enfant})
        )

    patchAddress = (index) ->
      usager = $scope.usagers[index]
      payload = {adresse: usager.resource.adresse}
      Backend.all("usagers/#{usager.resource.usager_existant.id}/localisations")
        .post(payload, null, {"if-match": usager.resource.usager_existant._version}).then(
          (usagerResource) ->
            if usager.type in ["usager_1", "usager_2"]
              recueil_da[usager.type].usager_existant._version = usagerResource._version
            else
              recueil_da.enfants[index_enfant].usager_existant._version = usagerResource._version
            usager.patchAddress = "success"
            usager.patchAll = "success"
            nextUsager(++index)
          (error) ->
            usager.patchAddress = "failure"
            usager.patchAll = "failure"
            $modalInstance.close({success: false, errors: error, type_usager: usager.type, index_enfant: usager.index_enfant})
        )


    postRecueil = ->
      $scope.post_recueil = "sending"
      for usager in $scope.usagers or []
        if usager.type in ["usager_1", "usager_2"]
          recueil_da[usager.type] = clean_usager_existant(usager.resource)
          recueil_da[usager.type].usager_existant =
            id: usager.resource.usager_existant.id
        else
          recueil_da.enfants[usager.index_enfant] = clean_usager_existant(usager.resource)
          recueil_da.enfants[usager.index_enfant].usager_existant =
            id: usager.resource.usager_existant.id
      Backend.all('recueils_da').post(recueil_da).then(
        (recueil_da_resource) ->
          $scope.post_recueil = "success"
          $modalInstance.close({success: true, recueil_da: recueil_da_resource})
        (error) ->
          $scope.post_recueil = "failure"
          $modalInstance.close({success: false, errors: error})
      )

    putRecueil = ->
      $scope.post_recueil = "sending"
      for usager in $scope.usagers or []
        if usager.type in ["usager_1", "usager_2"]
          recueil_da[usager.type] = clean_usager_existant(usager.resource)
          recueil_da[usager.type].usager_existant =
            id: usager.resource.usager_existant.id
        else
          recueil_da.enfants[usager.index_enfant] = clean_usager_existant(usager.resource)
          recueil_da.enfants[usager.index_enfant].usager_existant =
            id: usager.resource.usager_existant.id
      recueil_da.put(null, {'if-match': recueil_da._version}).then(
        (recueil_da_resource) ->
          $scope.post_recueil = "success"
          recueil_da.id = recueil_da_resource.id
          recueil_da._version = recueil_da_resource._version
          if action_switch == "save"
            $modalInstance.close({success: true, recueil_da: recueil_da_resource})
          else if action_switch == "validate"
            postDemandeursIdentifies()
          else if action_switch == "finish"
            postExploite()
        (error) ->
          $scope.post_recueil = "failure"
          $modalInstance.close({success: false, errors: error, action_switch: "save"})
      )

    postDemandeursIdentifies = ->
      $scope.post_next_etat = "sending"
      Backend.all('recueils_da/' + recueil_da.id + '/demandeurs_identifies')
        .post(null, null, null, {'if-match': recueil_da._version}).then(
          (recueil_da_resource) ->
            $scope.post_next_etat = "success"
            $modalInstance.close({success: true, recueil_da: recueil_da_resource})
          (error) ->
            $scope.post_next_etat = "failure"
            $modalInstance.close({success: false, errors: error, action_switch: action_switch})
        )

    postExploite = ->
      $scope.post_next_etat = "sending"
      Backend.all('recueils_da/' + recueil_da.id + '/exploite')
        .post(null, null, null, {'if-match': recueil_da._version}).then(
          (recueil_da_resource) ->
            $scope.post_next_etat = "success"
            $modalInstance.close({success: true, recueil_da: recueil_da_resource})
          (error) ->
            $scope.post_next_etat = "failure"
            $modalInstance.close({success: false, errors: error, action_switch: action_switch})
        )


    clean_usager_existant = (usager) ->
      copy = {}
      angular.copy(usager, copy)
      copy.identifiant_agdref = undefined
      copy.identifiants_eurodac = undefined
      copy.nom = undefined
      copy.origine_nom = undefined
      copy.nom_usage = undefined
      copy.origine_nom_usage = undefined
      copy.prenoms = undefined
      copy.photo = undefined
      copy.sexe = undefined
      copy.date_naissance = undefined
      copy.date_naissance_approximative = undefined
      copy.pays_naissance = undefined
      copy.ville_naissance = undefined
      if copy.nationalites?
        copy.nationalites = undefined
      copy.nom_pere = undefined
      copy.prenom_pere = undefined
      copy.nom_mere = undefined
      copy.prenom_mere = undefined
      copy.situation_familiale = undefined
      if copy.representant_legal_nom?
        copy.representant_legal_nom = undefined
      if copy.representant_legal_prenom?
        copy.representant_legal_prenom = undefined
      if copy.representant_legal_personne_morale?
        copy.representant_legal_personne_morale = undefined
      if copy.representant_legal_personne_morale_designation?
        copy.representant_legal_personne_morale_designation = undefined
      copy.telephone = undefined
      copy.email = undefined
      copy.langues = undefined
      copy.langues_audition_OFPRA = undefined
      copy.adresse = undefined
      copy.ecv_valide = undefined
      copy.identifiant_portail_agdref = undefined
      copy.vulnerabilite = undefined
      return copy
    nextUsager(0)
