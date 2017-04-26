'use strict'

angular.module('app.views.plage_rdv.modal', ['xin.form', 'xin.backend',
                                             'xin.plage_rdv', 'angularMoment'])

  .controller 'ModalInstanceShowCreneauController', ($scope, $modalInstance, event) ->
    $scope.event = event

    $scope.close = ->
      $modalInstance.dismiss()


  .controller 'ModalInstanceShowPlageController', ($scope, $modalInstance, event) ->
    $scope.event = event
    $scope.plage_guichets = event.plage_guichets or 1
    $scope.duree_creneau = event.duree_creneau or 45
    $scope.marge = event.marge or 30
    $scope.marge_initiale = event.marge_initiale or false

    $scope.cancel = ->
      return $modalInstance.dismiss('close')


  .controller 'ModalInstanceConfigureSiteController', ($scope, $modalInstance, Backend, siteId) ->
    $scope._error = undefined

    Backend.one('/sites/' + siteId).get().then(
      (site) ->
        $scope.limite_rdv_jrs = site.limite_rdv_jrs
        $scope.configureSite = ->
          Backend.one('/sites/' + siteId).patch({'limite_rdv_jrs' : $scope.limite_rdv_jrs}).then(
            (new_site) ->
              $modalInstance.close($scope.limite_rdv_jrs)
            (error) ->
              $scope._error = "Veuillez choisir un délai valide"
              throw error
          )

        $scope.cancel = ->
          $modalInstance.dismiss()
    )


  .controller 'ModalInstanceDeleteCreneauPeriod', ($scope, $modalInstance) ->
    $scope.deleteCreneaux = ->
      if $scope.suppression_type == 'day'
        day_to_suppress = moment($scope.day_to_suppress.substr(0, 10)).utc()
        date_debut = day_to_suppress.format("YYYY-MM-DD[T]HH:mm:ss[Z]")
        date_fin = day_to_suppress.add(1, "day").format("YYYY-MM-DD[T]HH:mm:ss[Z]")
        $modalInstance.close(
          date_debut: date_debut
          date_fin: date_fin
        )
      else if $scope.suppression_type == 'period'
        $modalInstance.close(
          date_debut: moment($scope.date_begin_to_suppress).format('YYYY-MM-DD[T]HH:mm:ss[Z]')
          date_fin: moment($scope.date_end_to_suppress).format('YYYY-MM-DD[T]HH:mm:ss[Z]')
        )

    $scope.cancel = ->
      $modalInstance.dismiss()


  .controller 'ModalInstanceAddCreneauController', ($scope, $modalInstance, event) ->

    # Step and OK button informations
    $scope.validation = false
    $scope.ok_button_label = 'Transformer la plage en créneaux'
    $scope.conf_button_label = 'Configurer la plage'
    $scope.event = event
    $scope.plage_guichets = event.plage_guichets or 1
    $scope.duree_creneau = event.duree_creneau or 45
    $scope.marge = event.marge or 30
    $scope.marge_initiale = event.marge_initiale or false

    closeModal = ->
      event.plage_guichets = $scope.plage_guichets
      event.duree_creneau = $scope.duree_creneau
      event.marge = $scope.marge
      event.marge_initiale = $scope.marge_initiale
      $modalInstance.close(true)

    findErrors = ->
      $scope._error = undefined
      duree_max = $scope.event.end.diff($scope.event.start, "minutes")
      if $scope.duree_creneau > duree_max
        $scope._error = "Vous devez agrandir la fenêtre de la plage de rendez-vous afin de créer des créneaux de rendez-vous dont la durée est supérieure à #{duree_max}min."
      if not $scope.plage_guichets
        $scope._error = "Le nombre d'agents disponibles doit être supérieur ou égal à 1."
      if not $scope.duree_creneau
        $scope._error = "La durée d'un créneau ne doit pas être nulle."
      return $scope._error?

    findWarnings = ->
      $scope._error = undefined
      if $scope.plage_guichets > 10
        $scope._error = "Vous avez saisi un nombre supérieur à 10 pour le nombre d'agents simultanément disponibles. Confirmez-vous cette saisie ?"
      return $scope._error?

    $scope.cancel = ->
      if not $scope.validation
        return $modalInstance.dismiss()
      # If validation status, cancel button is equal to undo button
      $scope.validation = false
      $scope.ok_button_label = 'Transformer la plage en créneaux'
      $scope.conf_button_label = 'Configurer la plage'

    $scope.ok = ->
      # Display error message
      if findErrors()
        return
      # If validation status, return modal informations
      if $scope.validation
        closeModal()
      # Display warning message
      findWarnings()
      $scope.validation = true
      $scope.ok_button_label = 'Oui, transformer la plage en créneaux'

    $scope.confPlage = ->
      # Display error message
      if findErrors()
        return
      # If validation status or no warning message, return modal informations
      if $scope.validation or not findWarnings()
        closeModal()
      $scope.validation = true
      $scope.conf_button_label = 'Oui, configurer la plage'

    $scope.deletePlage = ->
      $modalInstance.close(false)


  .controller 'ModalApplyModelesController', ($scope, $modalInstance, Backend, Calendar,
                                              modele, siteId) ->

    $scope.modeleType = modele.type
    type = if $scope.modeleType == "QUOTIDIEN" then "day" else "week"
    $scope.calendar = new Calendar(siteId, type, false)
    # Step and OK button informations
    $scope.validation = false
    $scope.button_label = 'Appliquer le modèle sur la période'
    $scope.applyDone = {}
    # Get modele informations (libelle + creneaux)
    $scope.libelle = modele.libelle
    if $scope.modeleType == 'QUOTIDIEN'
      for source in modele.daySources
        $scope.calendar.eventSources.push(source)
    else
      for source in modele.weekSources
        $scope.calendar.eventSources.push(source)

    findErrors = ->
      $scope._error = undefined
      duration = moment($scope.end).diff(moment($scope.begin), "months")
      if $scope.calendar.eventSources.length == 0
        $scope._error = "Veuillez configurer un modèle quotidien"
      else if !$scope.begin or !$scope.end
        $scope._error = "Veuillez sélectionner une date de début et une date de fin de période"
      else if duration < 0
        $scope._error = "Veuillez sélectionner une période valide.\nLa date de début doit commencer avant la date de fin de période"
      else if duration > 6
        $scope._error = "Veuillez sélectionner une période de six mois maximum"
      return $scope._error?

    closeModal = ->
      if $scope.modeleType == 'QUOTIDIEN'
        $modalInstance.close({
          begin: moment($scope.begin, 'YYYY-MM-DD')
          end: moment($scope.end, 'YYYY-MM-DD')
          monday: $scope.monday
          tuesday: $scope.tuesday
          wednesday: $scope.wednesday
          thursday: $scope.thursday
          friday: $scope.friday
          saturday: $scope.saturday
          sunday: $scope.sunday
        })
      else
        $modalInstance.close({
          begin: moment($scope.begin, 'YYYY-MM-DD')
          end: moment($scope.end, 'YYYY-MM-DD')
        })

    $scope.cancel = ->
      if not $scope.validation
        return $modalInstance.dismiss()
      # If validation status, cancel button is equal to undo button
      $scope.validation = false
      $scope.button_label = 'Appliquer le modèle sur la période'

    $scope.ok = ->
      # Display error message
      if findErrors()
        $scope.applyDone.end()
        return
      # If validation status, return modal informations
      if $scope.validation
        closeModal()
      # Else, check if creneaux already exist between begin/end dates.
      end = moment($scope.end, 'YYYY-MM-DD').format('YYYY-MM-DD[T]23:59:59[Z]')
      url = "sites/#{siteId}/creneaux?fq=date_debut:[#{$scope.begin} TO #{end}]"
      Backend.all(url).getList().then (creneaux) ->
        if creneaux.length
          $scope.validation = true
          $scope.button_label = 'Oui, appliquer le modèle sur la période'
        else
          closeModal()
        $scope.applyDone.end()


  .controller 'ModalConfigureModelesController', ($scope, $modalInstance, Backend, guid, Calendar,
                                                  siteId, modeleType) ->

    $scope.modeleType = modeleType
    type = if modeleType == "QUOTIDIEN" then "day" else "week"
    $scope.calendar = new Calendar(siteId, type, true)
    # Step and OK button informations
    $scope.validation = false
    $scope.ok_button_label = 'Utiliser le modèle'
    $scope.modeles = {
      all: []
      index: ""
      new: ""
    }

    # Find saved modeles
    Backend.all("sites/#{siteId}/modeles").getList().then(
      (modeles) ->
        $scope.selectModeles = []
        $scope.selectModeles.push {id: "#{_index}", libelle: modele.libelle} for modele, _index in modeles when modele.type == $scope.modeleType
        $scope.modeles.all = angular.copy(modeles)
        $scope.modeles.index = ""
      (error) -> throw error
    )

    # Select modeles
    $scope.$watch 'modeles.index', (value) ->
      # Clear Array
      $scope.calendar.eventSources.splice(0, $scope.calendar.eventSources.length)

      if value? and value isnt ""
        modele = $scope.modeles.all[value]
        $scope.modeles.new = modele.libelle
        for plage in modele.plages
          if $scope.modeleType == 'QUOTIDIEN'
            diff_days = moment().endOf('day').diff(moment(plage.plage_debut), 'days')
            start = moment(plage.plage_debut).add(diff_days, 'days')
            end = moment(plage.plage_fin).add(diff_days, 'days')
          else
            diff_weeks = moment().endOf('week').diff(moment(plage.plage_debut), "week")
            start = moment(plage.plage_debut).add(diff_weeks, "week")
            end = moment(plage.plage_fin).add(diff_weeks, "week")
          $scope.calendar.eventSources.push([{
            guid: guid()
            type: 'plage'
            title: "Cliquez pour configurer la plage\n \
                    Nombre d'agents : #{plage.plage_guichets}\n \
                    Durée d'un créneau : #{plage.duree_creneau }\n \
                    Marge : #{plage.marge}"
            backgroundColor: '#4EA9A0'
            start: start
            end: end
            plage_guichets: plage.plage_guichets or 1
            duree_creneau: plage.duree_creneau or 45
            marge: plage.marge or 0
            marge_initiale: plage.marge_initiale or false
          }])
      else
        $scope.modeles.new = ""

    findErrors = (check)->
      $scope._info = undefined
      $scope._error = undefined
      if $scope.calendar.eventSources.length is 0
        $scope._error = 'Une erreur est survenue. Le modèle ne comporte pas de plages horaires.'
      else if check == 'name' and $scope.modeles.new == ''
        $scope._error = 'Une erreur est survenue. Veuillez compléter le nom du modèle'
      else if check == 'index' and $scope.modeles.index == ''
        $scope._error = "Une erreur est survenue. Aucun modèle n'a été sélectionné"
      return $scope._error?

    $scope.cancel = ->
      if not $scope.validation
        return $modalInstance.dismiss('close')
      # If validation status, cancel button is equal to undo button
      $scope.validation = false
      $scope.ok_button_label = 'Utiliser le modèle'
      $scope.calendar.editable = true

    $scope.ok = ->
      # Display error message
      if findErrors()
        return
      # If validation status, return modal informations
      if $scope.validation
        $modalInstance.close({
          libelle: $scope.modeles.new
          type: $scope.modeleType
          daySources: if $scope.modeleType == 'QUOTIDIEN' then $scope.calendar.eventSources
          weekSources: if $scope.modeleType == 'HEBDOMADAIRE' then $scope.calendar.eventSources
        })
      $scope.validation = true
      $scope.ok_button_label = 'Oui, utiliser le modèle'
      $scope.calendar.editable = false
      if $scope.modeles.new == ''
        $scope.modeles.new = "Modèle #{$scope.modeleType}"

    $scope.save = ->
      # Display error message
      if findErrors('name')
        return
      payload = {
        type: $scope.modeleType
        libelle: $scope.modeles.new
        plages: []
      }
      for source in $scope.calendar.eventSources
        payload.plages.push({
          plage_debut: source[0].start
          plage_fin: source[0].end
          plage_guichets: source[0].plage_guichets or 1
          duree_creneau: source[0].duree_creneau or 45
          marge: source[0].marge or 0
          marge_initiale: source[0].marge_initiale or false
        })

      if $scope.modeles.index isnt ""
        # Update modele
        Backend.one("sites/#{siteId}/modeles").patch(payload).then(
          (modeles) ->
            $scope._info = 'le modèle a bien été modifié'
            $scope.selectModeles = []
            $scope.selectModeles.push {id: "#{_index}", libelle: modele.libelle} for modele, _index in modeles['_items'] when modele.type == $scope.modeleType
            $scope.modeles.all = angular.copy(modeles['_items'])
          (error) ->
            $scope._error = "Une erreur est survenue. Le modèle n'a pas pu être modifié"
            throw error
        )
      else
        # Create new modele
        Backend.all("sites/#{siteId}/modeles").post(payload).then(
          (modeles) ->
            $scope._info = 'le modèle a bien été enregistré'
            $scope.selectModeles = []
            $scope.selectModeles.push {id: "#{_index}", libelle: modele.libelle} for modele, _index in modeles['_items'] when modele.type == $scope.modeleType
            $scope.modeles.all = angular.copy(modeles['_items'])
            $scope.modeles.index = "#{$scope.modeles.all.length - 1}"
          (error) ->
            $scope._error = "Une erreur est survenue. Le modèle n'a pas pu être enregistré"
            if error.status is 400
              $scope._error = "#{$scope._error} Le nom du nouveau modèle est déjà utilisé par un modèle #{error.data._errors?[0].libelle?.split(':')[1]}"
            throw error
        )

    $scope.delete = ->
      # Display error message
      if findErrors('index')
        return
      payload = {
        libelle: $scope.modeles.new
        type: $scope.modeleType
        plages: []
      }
      Backend.one("sites/#{siteId}/modeles").patch(payload).then(
        (modeles) ->
          $scope._info = 'le modèle a bien été supprimé'
          $scope.selectModeles = []
          $scope.selectModeles.push {id: "#{_index}", libelle: modele.libelle} for modele, _index in modeles['_items'] when modele.type == $scope.modeleType
          $scope.modeles.all = angular.copy(modeles['_items'])
          $scope.modeles.index = ''
        (error) ->
          $scope._error = "Une erreur est survenue. Le modèle n'a pas pu être supprimé"
          throw error
      )
