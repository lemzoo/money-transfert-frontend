"use strict"

angular.module('app.views.da_service', [])
  .factory "postNewRight", ($q, BackendWithoutInterceptor) ->
    (right) ->
      defer = $q.defer()
      droit_payload =
        date_decision_sur_attestation: right.date_decision_sur_attestation
        date_debut_validite: right.date_debut_validite
        date_fin_validite: right.date_fin_validite
        demande_origine: right.demande_origine
        type_document: right.type_document
        sous_type_document: right.sous_type_document
        usager: right.usager
      BackendWithoutInterceptor.all('droits').post(droit_payload).then(
        (right) -> defer.resolve(right)
        (error) -> defer.reject(error)
      )
      return defer.promise

  .factory "postNewSupport", ($q, BackendWithoutInterceptor) ->
    (url, lieu_delivrance) ->
      defer = $q.defer()
      support_payload =
        "date_delivrance": moment()
        "lieu_delivrance": lieu_delivrance
      BackendWithoutInterceptor.all(url).post(support_payload).then(
        (right) -> defer.resolve(right)
        (error) -> defer.reject(error)
      )
      return defer.promise

  .factory "patchDA", ($q, BackendWithoutInterceptor) ->
    (da, right) ->
      defer = $q.defer()
      da_payload =
        "decision_sur_attestation": right.decision_sur_attestation
        "date_decision_sur_attestation": right.date_decision_sur_attestation
        "renouvellement_attestation": da.renouvellement_attestation += 1
      BackendWithoutInterceptor.all("demandes_asile/#{da.id}").patch(da_payload).then(
        (da) -> defer.resolve(da)
        (error) -> defer.reject(error)
      )
      return defer.promise

  .factory "makeDuplicata", ($q, BackendWithoutInterceptor) ->
    (right, motif, last_support, lieu_delivrance) ->
      defer = $q.defer()
      payload =
        "date_delivrance": moment()
        "lieu_delivrance": lieu_delivrance
      BackendWithoutInterceptor.all(right._links.support_create).post(payload).then(
        (droit) ->
          BackendWithoutInterceptor.all(last_support._links.annuler)
            .post({"motif_annulation": motif})
          defer.resolve(droit)
        (error) -> defer.reject(error)
      )
      return defer.promise

  .factory "makeReedition", ($q, BackendWithoutInterceptor, postNewRight,
                             patchDA, postNewSupport) ->
    (daId, right, lieu_delivrance) ->
      defer = $q.defer()
      postNewRight(right).then(
        (droit) ->
          da_payload =
            'date_decision_sur_attestation' : right.date_decision_sur_attestation
          BackendWithoutInterceptor.all("demandes_asile/#{daId}").patch(da_payload).then(
            () ->
              postNewSupport(droit._links.support_create, lieu_delivrance).then(
                (droit) -> defer.resolve(droit)
                (error) -> defer.reject(error)
              )
            (error) -> defer.reject(error)
          )
        (error) -> defer.reject(error)
      )
      return defer.promise

  .factory "makeRenouvellement", ($q, BackendWithoutInterceptor, postNewRight,
                                  patchDA, postNewSupport) ->
    (da, right, last_decision_attestation, lieu_delivrance) ->
      defer = $q.defer()
      if not last_decision_attestation? or last_decision_attestation
        postNewRight(right).then(
          (droit) ->
            patchDA(da, right).then(
              () ->
                postNewSupport(droit._links.support_create, lieu_delivrance).then(
                  (droit) -> defer.resolve(droit)
                  (error) -> defer.reject(error)
                )
              (error) -> defer.reject(error)
            )
          (error) -> defer.reject(error)
        )
      else
        patchDA(da, right).then(
          (da) ->
            da_payload =
              type_document: right.type_document
              sous_type_document: right.sous_type_document
              delivrance: true
              motif: right.motif
              date_decision: right.date_decision_sur_attestation
            BackendWithoutInterceptor.all("demandes_asile/#{da.id}/decisions_attestations").post(da_payload).then(
              (da) ->
                postNewRight(right).then(
                  (droit) ->
                    postNewSupport(droit._links.support_create, lieu_delivrance).then(
                      (droit) -> defer.resolve(droit)
                      (error) -> defer.reject(error)
                    )
                  (error) -> defer.reject(error)
                )
              (error) -> defer.reject(error)
            )
          (error) -> defer.reject(error)
        )
      return defer.promise

  .factory "makeNoDelivrance", ($q, BackendWithoutInterceptor) ->
    (da, right) ->
      defer = $q.defer()
      da_payload =
        type_document: right.type_document
        sous_type_document: right.sous_type_document
        delivrance: false
        motif: right.motif
        date_decision: right.date_decision_sur_attestation
      BackendWithoutInterceptor.all("demandes_asile/#{da.id}/decisions_attestations")
        .post(da_payload).then(
          (da) ->
            da_payload =
              "decision_sur_attestation": false
              "date_decision_sur_attestation": right.date_decision_sur_attestation
              "renouvellement_attestation": da.renouvellement_attestation += 1
            BackendWithoutInterceptor.all("demandes_asile/#{da.id}").patch(da_payload).then(
              (da) -> defer.resolve(da)
              (error) -> defer.reject(error)
            )
          (error) -> defer.reject(error)
        )
      return defer.promise

  .factory "manageErrors", () ->
    (error) ->
      _errors = error.data
      for key, value of _errors
        if Array.isArray(value)
          if value[0] in ["Field may not be null.", "Missing data for required field.", "Not a valid datetime."]
            _errors[key] = "Champ requis."
      for key, value of _errors
        if key == "motif"
          _errors.motif_decision_attestation =
            refus: value
        else if key == "date_decision_sur_attestation"
          _errors.date_decision = value
      return _errors
