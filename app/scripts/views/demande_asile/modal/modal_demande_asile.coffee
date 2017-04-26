"use strict"

angular.module('app.views.demande_asile.modal', ['xin.form', 'sc-toggle-switch',
                                                 'app.views.da_service'])
  .controller 'ModalEditionAttestationController', ($scope, $modalInstance, $route,
                                                    Backend, session, da, droits,
                                                    makeDuplicata, makeReedition,
                                                    makeRenouvellement, makeNoDelivrance,
                                                    manageErrors) ->
    $scope.da = {}
    angular.copy(da, $scope.da)
    $scope.renouvellement_confirmed = false
    $scope.duplicataDone = {}
    $scope.reeditionDone = {}
    $scope.renewalDone = {}
    $scope.noDeliveryDone = {}
    lieu_delivrance = null
    session.getUserPromise().then (user) ->
      if user.site_affecte?
        Backend.one("/sites/#{user.site_affecte.id}").get().then(
          (site_affecte) ->
            lieu_delivrance = site_affecte.id
            if site_affecte.autorite_rattachement?
              Backend.one("/sites/#{site_affecte.autorite_rattachement.id}").get().then(
                (autorite) ->
                  lieu_delivrance = autorite.id
              )
        )
    $scope.choice = "NO_CHOICE"
    $scope.decisionSurAttestationAllowed = false
    $scope.decision_sur_attestation = $scope.da.decision_sur_attestation
    $scope.DateDeDecisionAllowed = false
    $scope.date_decision_sur_attestation = $scope.da.date_decision_sur_attestation
    $scope.duplicata_motif = ""
    $scope.duplicata_need_motif = false
    $scope.duplicata_enabled = true
    $scope.duplicata_disabled_motif = null
    $scope.reedition_enabled = true
    $scope.reedition_disabled_motif = null
    $scope.renouvellement_enabled = true
    $scope.renouvellement_disabled_motif = null
    $scope.motif_decision_attestation =
      accord: null
      refus: null
    $scope.allow_motif_delivrance_attestation = false
    $scope.motif_delivrance_attestation = []
    $scope.motif_non_delivrance_attestation = []
    $scope.recevabilite = null
    if da.type_demande == "REEXAMEN"
      if da.recevabilites? and da.recevabilites.length
        $scope.recevabilite = da.recevabilites[da.recevabilites.length-1]
        if not $scope.recevabilite.recevabilite
          $scope.motif_delivrance_attestation = [
            "id": "DEMANDE_NON_DILATOIRE"
            "libelle": "Demande jugée non dilatoire par le préfet"
          ]
          $scope.motif_decision_attestation.accord = "DEMANDE_NON_DILATOIRE"
      $scope.decisionSurAttestationAllowed = true
      $scope.DateDeDecisionAllowed = true
      if da.numero_reexamen == 1
        $scope.motif_non_delivrance_attestation = [
          'id': 'DEMANDE_IRRECEVABLE'
          'libelle': "Demande irrecevable et destinée à faire obstacle à un éloignement (L.743-2 4°)"
        ,
          'id': 'AUTRE'
          'libelle': "Autre"
        ]
      else
        $scope.motif_non_delivrance_attestation = [
          'id': 'DEUXIEME_DEMANDE_REEXAMEN'
          'libelle': "Deuxième demande de réexamen ou réexamen ultérieur"
        ,
          'id': 'AUTRE'
          'libelle': "Autre"
        ]
    last_droit = null
    last_support = null
    if droits? and droits.length
      last_droit = droits[droits.length-1]
    # duplicata
    if last_droit? and last_droit.supports? and last_droit.supports.length > 0
      last_support = last_droit.supports[last_droit.supports.length-1]
      $scope.duplicata_need_motif = true
    else
      $scope.duplicata_enabled = false
      $scope.duplicata_disabled_motif = "Il n'y a pas eu de d'attestation délivrée pour le droit en cours."
    # button duplicata/reedition if decision_sur_attestation == false
    if not da.decision_sur_attestation
      $scope.duplicata_enabled = false
      $scope.duplicata_disabled_motif = "Seul un renouvellement est possible pour délivrer une attestion après un refus de délivrance."
      $scope.reedition_enabled = false
      $scope.reedition_disabled_motif = "Seul un renouvellement est possible pour délivrer une attestion après un refus de délivrance."

    # reedition
    procedure = ''
    if $scope.da.procedure.type == 'NORMALE'
      procedure = 'normale'
    else if $scope.da.procedure.type == 'ACCELEREE'
      procedure = 'acceleree'
    else if $scope.da.procedure.type == 'DUBLIN'
      procedure = 'dublin'
    sous_type_document = null
    duree_procedure = {}
    $scope.date_debut_validite = null

    parametrage = null
    Backend.one('parametrage').get().then(
      (result) ->
        parametrage = result.plain()
    )

    setDureeAttestation = (edition_type) ->
      duree_attestation = null
      if edition_type in ["DUPLICATA", "REEDITION"]
        if $scope.da.renouvellement_attestation == 1
          sous_type_document = 'PREMIERE_DELIVRANCE'
          duree_attestation = ((parametrage.duree_attestation or {}).premiere_delivrance or {})
        else if $scope.da.renouvellement_attestation == 2
          sous_type_document = 'PREMIER_RENOUVELLEMENT'
          duree_attestation = ((parametrage.duree_attestation or {}).premier_renouvellement or {})
        else if $scope.da.renouvellement_attestation >= 3
          sous_type_document = 'EN_RENOUVELLEMENT'
          duree_attestation = ((parametrage.duree_attestation or {}).en_renouvellement or {})
      else if edition_type == "RENOUVELLEMENT"
        if $scope.da.renouvellement_attestation == 1
          sous_type_document = 'PREMIER_RENOUVELLEMENT'
          duree_attestation = ((parametrage.duree_attestation or {}).premier_renouvellement or {})
        else if $scope.da.renouvellement_attestation >= 2
          sous_type_document = 'EN_RENOUVELLEMENT'
          duree_attestation = ((parametrage.duree_attestation or {}).en_renouvellement or {})
      duree_procedure = (duree_attestation[procedure] or {'an' : 0, 'mois' : 0, 'jour' : 0})
      $scope.$watch 'date_debut_validite', (value) ->
        $scope.date_fin_validite = moment(value).utc()
        if $scope.date_fin_validite.date() == 1
          $scope.date_fin_validite.add(duree_procedure.mois, 'month')
          $scope.date_fin_validite.add(duree_procedure.jour, 'day')
        else
          $scope.date_fin_validite.add(duree_procedure.jour, 'day')
          $scope.date_fin_validite.add(duree_procedure.mois, 'month')
        $scope.date_fin_validite.add(duree_procedure.an, 'year')

    $scope.duplicata = ->
      $scope.choice = "DUPLICATA"
      $scope.decisionSurAttestationAllowed = false
      $scope.DateDeDecisionAllowed = false
      setDureeAttestation("DUPLICATA")

    $scope.reedit = ->
      $scope.choice = "REEDITION"
      $scope.decisionSurAttestationAllowed = false
      if last_droit?
        $scope.date_debut_validite = last_droit.date_debut_validite
      else
        $scope.date_debut_validite = moment($scope.date_decision_sur_attestation)
      $scope.DateDeDecisionAllowed = true
      setDureeAttestation("REEDITION")

    $scope.renewal = ->
      $scope.choice = "RENOUVELLEMENT"
      $scope.decisionSurAttestationAllowed = false
      $scope.$watch 'date_decision_sur_attestation', (value) ->
        if value?
          $scope.date_debut_validite = moment(value)
      $scope.date_decision_sur_attestation = new Date()
      $scope.DateDeDecisionAllowed = true
      setDureeAttestation("RENOUVELLEMENT")

    $scope.saveNoDelivery = ->
      $scope._errors = {}
      setDureeAttestation("RENOUVELLEMENT")
      right =
        "decision_sur_attestation": $scope.decision_sur_attestation
        "motif": $scope.motif_decision_attestation.refus
        "date_decision_sur_attestation" : $scope.date_decision_sur_attestation
        "sous_type_document" : sous_type_document
        "demande_origine" : {"id" : da.id, "_cls": "DemandeAsile"}
        "type_document" : "ATTESTATION_DEMANDE_ASILE"
        "usager" : da.usager.id
      makeNoDelivrance(da, right).then(
        () ->
          $route.reload()
          $modalInstance.close()
        (error) ->
          $scope._errors = manageErrors(error)
          $scope.noDeliveryDone.end()
      )

    $scope.saveDuplicata = ->
      $scope._errors = {}
      if (not $scope.motif_annulation? or $scope.motif_annulation == "")
        $scope._errors.motif_annulation = "Champ obligatoire pour un duplicata"
        $scope.duplicataDone.end()
        return
      else if ($scope.motif_annulation == 'DEGRADATION' and not $scope.duplicata_destruction)
        $scope._errors.motif_annulation = "Merci de confirmer la destruction du précédent support."
        $scope.duplicataDone.end()
        return
      makeDuplicata(last_droit, $scope.motif_annulation, last_support, lieu_delivrance).then(
        (droit) ->
          $modalInstance.close({droit: droit, duplicata: true})
        (error) ->
          $scope._errors = manageErrors(error)
          $scope.duplicataDone.end()
      )

    $scope.saveReedition = ->
      $scope._errors = null
      if not $scope.destruction
        $scope.motif_error = "Merci de confirmer la destruction de la précédente attestation."
        $scope.reeditionDone.end()
        return
      right =
        "decision_sur_attestation": $scope.decision_sur_attestation
        "motif": $scope.motif_decision_attestation
        "date_decision_sur_attestation" : $scope.date_decision_sur_attestation
        "date_debut_validite" : $scope.date_debut_validite
        "date_fin_validite" : $scope.date_fin_validite
        "sous_type_document" : sous_type_document
        "demande_origine" : {"id" : $scope.da.id, "_cls": "DemandeAsile"}
        "type_document" : "ATTESTATION_DEMANDE_ASILE"
        "usager" : da.usager.id
      makeReedition(da.id, right, lieu_delivrance).then(
        (droit) ->
          $modalInstance.close({droit: droit})
        (error) ->
          $scope._errors = manageErrors(error)
          $scope.reeditionDone.end()
      )

    $scope.saveRenewal = ->
      if not $scope.renouvellement_confirmed
        $scope.renouvellement_confirmed = true
        $scope.renewalDone.end()
        return
      $scope._errors = null
      right =
        "decision_sur_attestation": $scope.decision_sur_attestation
        "motif": $scope.motif_decision_attestation.accord
        "date_decision_sur_attestation" : $scope.date_decision_sur_attestation
        "date_debut_validite" : $scope.date_debut_validite
        "date_fin_validite" : $scope.date_fin_validite
        "sous_type_document" : sous_type_document
        "demande_origine" : {"id" : $scope.da.id, "_cls": "DemandeAsile"}
        "type_document" : "ATTESTATION_DEMANDE_ASILE"
        "usager" : da.usager.id
      last_decision_attestation = null
      if da.decisions_attestation?
        last_decision_attestation = da.decisions_attestation[da.decisions_attestation.length-1].decision
      makeRenouvellement(da, right, last_decision_attestation, lieu_delivrance).then(
        (droit) ->
          $modalInstance.close({droit: droit})
        (error) ->
          $scope._errors = manageErrors(error)
          $scope.renewalDone.end()
      )

    $scope.cancel = ->
      $scope.renouvellement_confirmed = false
      $scope._errors = {}
      if $scope.choice == 'NO_CHOICE'
        $modalInstance.close(false)
      else
        $scope.choice = "NO_CHOICE"
        $scope.decision_sur_attestation = da.decision_sur_attestation
        $scope.date_decision_sur_attestation = da.date_decision_sur_attestation
        if da.type_demande == "REEXAMEN"
          $scope.decisionSurAttestationAllowed = true
          $scope.DateDeDecisionAllowed = true


  .controller 'ModalInstanceRequalificationController', ($scope, $modalInstance, SETTINGS, Backend,
                                                         da) ->

    $scope.saveDone = {}
    $scope.requalification = {
      "date_notification": new Date()
    }
    $scope.etat = "form"

    $scope.selectTypeProcedure = [
      { id: 'NORMALE', libelle: 'Normale' },
      { id: 'ACCELEREE', libelle: 'Accélérée' },
      { id: 'DUBLIN', libelle: 'Dublin' }
    ]

    $scope.$watch 'requalification.type', (value) ->
      if value == ''
        $scope.requalification.motif_qualification = null
        $scope.selectMotifQualification = [{id:null, libelle: 'Commencez par choisir un type de procédure'}]

      else if value? and SETTINGS.QUALIFICATION[value]?
        $scope.selectMotifQualification = SETTINGS.QUALIFICATION[value]
      else
        $scope.selectMotifQualification = []
    , true

    $scope.cancel = ->
      $modalInstance.close(false)

    $scope.ok = ->
      delete $scope.requalification._errors
      $scope.requalification.acteur = "PREFECTURE"
      Backend.all("demandes_asile/#{da.id}/requalifications").post($scope.requalification).then(
        (success) ->
          if success.statut == "PRETE_EDITION_ATTESTATION"
            Backend.all("demandes_asile/#{da.id}").patch({renouvellement_attestation: 1}).then(
              () -> $scope.etat = "successAndRedirectToEditionAttestation"
              () -> $scope.etat = "successAndRedirectToEditionAttestation"
            )
          else
            $scope.etat = "success"
        (errors) ->
          manageErrors(errors.data)
      )

    $scope.finish = ->
      $modalInstance.close(true)

    $scope.attestationCible = ->
      $modalInstance.close(true)
      window.location = "#/attestations/#{da.id}"

    manageErrors = (errors) ->
      $scope.requalification._errors = {}
      if not errors?
        return
      for key, field of errors
        error = ""
        if field[0] in ["Missing data for required field.", "Field may not be null."]
          error = "Ce champ est obligatoire."
        else
          error = field[0]
        if key == "procedure"
          if field.requalifications
            if field.requalifications[0]? and field.requalifications[0].date_notification?
              $scope.requalification._errors.date_notification = field.requalifications[0].date_notification
            else if field.requalifications["1"]? and field.requalifications["1"].date_notification?
              $scope.requalification._errors.date_notification = field.requalifications["1"].date_notification
        $scope.requalification._errors[key] = error
      $scope.saveDone.end?()
