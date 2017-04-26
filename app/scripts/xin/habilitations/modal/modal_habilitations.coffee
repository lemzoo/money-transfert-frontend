'use strict'


angular.module('xin.habilitations.modal', ['xin.session', 'app.settings', 'xin.backend'])

  # Define the controller for this module
  #   Parameters :
  #     $scope            : the global angularJs scope
  #     $modalInstance    : the instance of the modal
  #     session           : the session from xin.session module
  #     SETTINGS          : application global settings from app.settings module
  #     Backend           : object from xin.backend module and used to send http request to the backend
  #     message           : the message to display in the pop-up
  #     alert_displayed   : flag to indicate whether the alert message is displayed
  #     cancel_displayed  : flag to indicate whether the cancel button is displayed
  #
  .controller 'modalHabilitationsController', ($scope, $window, $modalInstance, session, SETTINGS,
                                               Backend, message, alert_displayed, cancel_displayed) ->

    #
    # Configure the modal
    #
    $scope.modalInstance = $modalInstance
    $scope.buttonConfirmText = "Confirmer"
    $scope.buttonCancelText = "Annuler"
    $scope.message = message
    $scope.alertDisplayed = alert_displayed
    $scope.cancelDisplayed = cancel_displayed
    $scope.confirmDisabled = true

    $scope.settings = SETTINGS
    $scope.activeHabilitations = []
    $scope.habilitationSelectedId = null

    session.getUserPromise().then (user) ->
      # Fetch all user's habilitations as flat format
      # Assume that an unique user is connected
      Backend.one('moi/accreditations').get().then(
        (accrs) ->
          for accr in accrs._items
            # Find only active one
            if (not accr.fin_validite? || new Date(accr.fin_validite).getTime() > new Date().getTime())
              # Preselect the currently used accreditation
              accr.isSelected = accr.id == user.current_accreditation_id
              $scope.activeHabilitations.push accr

        (error) ->
          throw error
      )

    #
    # Close the dialog
    #
    $scope.cancel = ->
      $modalInstance.close(false)

    #
    # Confirm the dialog
    #
    $scope.confirm = ->
      $modalInstance.close(false)
      Backend.one('moi').patch(
          {'preferences': {'current_accreditation_id': $scope.habilitationSelectedId}})
        .then (data, status, headers, config) ->
          # Go back to root and reload page to reset the application
          $window.location.assign('/')
        .catch (data, status, headers, config) ->
          throw "Current accreditation preference update has failed: #{status}, #{data}"

    #
    # Highlight selected habilitation
    #
    $scope.selectHabilitation = (index) ->
      for habilitation in $scope.activeHabilitations
        # unselect all habilitation
        habilitation.isSelected = false

      # highlight only the one selected
      habilitation = ($scope.activeHabilitations.filter (item) -> item.id == index)[0]
      habilitation.isSelected = true

      $scope.habilitationSelectedId = index
      $scope.confirmDisabled = false
