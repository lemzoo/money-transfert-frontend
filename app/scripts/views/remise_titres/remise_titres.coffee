'use strict'

angular.module('app.views.remise_titres', ['ngRoute', 'app.settings', 'xin.session', 'xin.backend',
                                          'xin.pdf', 'app.views.remise_titres.modal','app.views.remise_titres.barcode_scanner'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/remise-titres',
        templateUrl: 'scripts/views/remise_titres/remise_titres.html'
        routeAccess: true
        breadcrumbs: 'Remise de titres'
        controller: 'remiseTitresController'


  .controller 'remiseTitresController', ($scope, $modal, Backend, pdfFactory) ->

      $scope.numero_timbre = ''
      $scope.numero_etranger = ''
      $scope.timbre_consommable = false
      $scope.timbre_consomme = false
      $scope.is_consuming_timbre = false
      $scope.date_paiement_effectue = ''
      $scope.usager = null
      $scope.can_open_modal = true
      $scope.timbre_input_id = 'numero_de_timbre'

      statuts_timbres_non_consommables =
        'achete':
          'libelle': 'EXPIRÉ'
          'message': 'Le timbre n\'est pas consommable : ce timbre a expiré.'
        'consomme':
          'libelle': 'CONSOMMÉ'
          'message': 'Le timbre n\'est pas consommable : ce timbre a déjà été consommé.'
        'annule':
          'libelle': 'ANNULÉ'
          'message': 'Le timbre n\'est pas consommable : ce timbre n\'est plus utilisable.'
        'rembourse':
          'libelle': 'REMBOURSÉ'
          'message': 'Le timbre n\'est pas consommable : ce timbre a été remboursé et n\'est plus utilisable.'
        'demande-de-remboursement':
          'libelle': 'EN DEMANDE DE REMBOURSEMENT'
          'message': 'Le timbre n\'est pas consommable : ce timbre fait l\'objet d\'une demande de remboursement.'
        'brule':
          'libelle': 'BRÛLÉ'
          'message': 'Le timbre n\'est pas consommable : ce timbre n\'est plus utilisable.'
        'impaye':
          'libelle': 'IMPAYÉ'
          'message': 'Le timbre n\'est pas consommable : ce timbre n\'est plus utilisable.'
        'mauvaise-serie':
          'libelle': 'MAUVAISE SÉRIE'
          'message': 'Le timbre n\'est pas consommable : ce timbre ne peut pas être utilisé pour cette démarche.'

      message_levels =
        ERROR: 'error'
        WAITING: 'waiting'
        INFO: 'info'
        SUCCESS: 'success'

      $scope.onScan = (scanned_value) ->
        parseNumeroTimbreFromScan = (scanned_value) ->
          scanned_value.slice(0, 16)

        fillTimbreInput = (numero_timbre) ->
          $('#' + $scope.timbre_input_id).val(numero_timbre)
          $scope.numero_timbre = numero_timbre

        if not $scope.usager?
          $scope.openUsagerSearchModal(scanned_value, {search_on_open: true})
        else if not $scope.statut_checked
          numero_timbre = parseNumeroTimbreFromScan(scanned_value)
          fillTimbreInput(numero_timbre)
          checkTimbreStatus()

      $scope.openUsagerSearchModal = (numero_etranger, options) ->
        if not $scope.can_open_modal
          return

        modalInstance = $modal.open(
          templateUrl: 'scripts/views/remise_titres/modal/fne.html'
          controller: 'ModalRechercheIDController'
          backdrop: false
          keyboard: false
          resolve:
            search_on_open: ->
              return options?.search_on_open or false
            numero_etranger: ->
              return numero_etranger or $scope.usager?.identifiant_agdref
        )

        onModalResult = (result) ->
          $scope.can_open_modal = false
          $scope.usager = result.usager
          if result.source == 'fne'
            $scope.usager.situation_familiale = "CELIBATAIRE"

        onModalDismiss = ->
          $scope.can_open_modal = true

        modalInstance.result.then onModalResult, onModalDismiss
        $scope.can_open_modal = false

      $scope.onNumeroTimbreSubmit = (event) ->
        event.preventDefault()
        checkTimbreStatus()

      checkTimbreStatus = () ->
        Backend.one('/timbres/'+$scope.numero_timbre).get()
          .then(updateTimbreInformation)
          .catch(handleErrors)

      updateTimbreInformation = (timbre_details) ->
        $scope.timbre_consommable = timbre_details.data.is_consommable

        if $scope.timbre_consommable
          $scope.libelle_timbre = 'CONSOMMABLE'
          updateUserMessage('Le timbre est prêt à être consommé.', message_levels.INFO )
        else
          statut_timbre = statuts_timbres_non_consommables[timbre_details.data.status]
          $scope.libelle_timbre =  statut_timbre.libelle
          updateUserMessage(statut_timbre.message, message_levels.ERROR)

        $scope.statut_checked = true
        $scope.montant_timbre = timbre_details.data.amount
        $scope.montant_timbre_en_euros = $scope.montant_timbre + ' €'

      updateUserMessage = (message, level) ->
        style = ''
        is_waiting = false

        switch level
          when message_levels.ERROR
            style = 'danger'

          when message_levels.WAITING
            style = 'warning'
            is_waiting = true

          when message_levels.INFO
            style = 'info'

          when message_levels.SUCCESS
            style = 'success'

        $scope.alert_message = message
        $scope.alert_style = style
        $scope.alert_is_waiting = is_waiting

      handleErrors = (response) ->
        liste_erreurs =
          'stamp-unknown' : 'Le timbre n\'est pas valide : ce timbre n’est pas reconnu.'
          'stamp-already-consumed': 'Le timbre a déjà été consommé.'
          'action-impossible': 'Le timbre ne peut pas être consommé.'
          'stamp-expired': 'La validité du timbre a expiré.'
          'bad-stamp-series': 'Le timbre n\'est pas consommable : ce timbre ne peut pas être utilisé pour cette démarche.'
          'bad-format': 'Le numéro de timbre est composé de 16 chiffres.'
          'stamp-status-unknown': 'Le timbre n\'est pas valide : le statut de ce timbre n\'est pas reconnu.'

        MESSAGE_ERREUR_INCONNUE = 'Nos services sont momentanément indisponibles. Nous nous efforçons de les rétablir rapidement. Vous pouvez réessayer plus tard.'

        code_erreur = response.data?.errors[0]?.code_erreur
        message_erreur = liste_erreurs[code_erreur] or MESSAGE_ERREUR_INCONNUE
        updateUserMessage(message_erreur, message_levels.ERROR)

      $scope.cancelConsumption = (event) ->
        event.preventDefault()
        resetCheckStatus()
        resetAlert()

      resetCheckStatus = () ->
        $scope.statut_checked = false
        $scope.libelle_timbre = ''
        $scope.montant_timbre = 0
        $scope.montant_timbre_en_euros = '− €'

      resetAlert = () ->
        $scope.alert_message = ''
        $scope.alert_style = ''
        $scope.alert_is_waiting = false

      $scope.consumeTimbre = (event) ->
        event.preventDefault()

        $scope.is_consuming_timbre = true
        MESSAGE_CONSUMING_TIMBRE = 'Le timbre est en cours de consommation'
        updateUserMessage(MESSAGE_CONSUMING_TIMBRE, message_levels.WAITING)

        payload = {
          'type_paiement': 'TIMBRE',
          'numero_timbre': $scope.numero_timbre,
          'numero_etranger': $scope.usager?.identifiant_agdref,
          'montant': $scope.montant_timbre,
          'etat_civil': {
            'nom': $scope.usager?.nom,
            'prenoms': $scope.usager?.prenoms,
            'sexe': $scope.usager?.sexe,
            'date_naissance': $scope.usager?.date_naissance,
            'codes_nationalites': $scope.usager?.nationalites?.map((nationalite) -> nationalite.code),
            'code_pays_naissance': $scope.usager?.pays_naissance?.code,
            'ville_naissance': $scope.usager?.ville_naissance,
            'situation_familiale': $scope.usager?.situation_familiale
          }
        }

        Backend.one('/').post('paiements', payload)
          .then(displaySuccessMessage)
          .catch(handleErrors)
          .then(() -> $scope.is_consuming_timbre = false)

      displaySuccessMessage = (timbre_details) ->
        $scope.date_paiement_effectue = timbre_details.data.date_paiement_effectue
        $scope.timbre_consomme = true
        MESSAGE_CONSUMED_TIMBRE = 'Le timbre a été consommé'
        $scope.libelle_timbre = statuts_timbres_non_consommables['consomme'].libelle
        updateUserMessage(MESSAGE_CONSUMED_TIMBRE, message_levels.SUCCESS)

      $scope.editConfirmation = (event) ->
        event.preventDefault()
        params = {
          'usager': $scope.usager
          'timbre': {
            'numero': $scope.numero_timbre,
            'montant': $scope.montant_timbre.toFixed(2),
            'date': $scope.date_paiement_effectue
          }
        }
        pdf = pdfFactory('remise_titres', params)
        pdf.generate()

      resetCheckStatus()
      resetAlert()
