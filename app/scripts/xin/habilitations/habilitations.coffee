'use strict'

angular.module('xin.habilitations', ['app.settings', 'sc-toggle-switch', 'xin.session',
                                     'xin.backend', 'xin.form', 'xin.referential',])

  .constant 'ADMINISTRATEUR_NATIONAL_CREATES_ROLES', [
    'ADMINISTRATEUR_NATIONAL',
    'ADMINISTRATEUR_PA',
    'ADMINISTRATEUR_PREFECTURE',
    'ADMINISTRATEUR_DT_OFII',
    'GESTIONNAIRE_NATIONAL'
    'RESPONSABLE_NATIONAL',
    'RESPONSABLE_ZONAL',
    'SUPPORT_NATIONAL',
    'SUPERVISEUR_ECHANGES',
    'SYSTEME_AGDREF',
    'SYSTEME_DNA',
    'SYSTEME_INEREC',
    'EXTRACTEUR'
  ]

  .constant 'ADMINISTRATEUR_PREFECTURE_CREATE_ROLES', [
    'RESPONSABLE_GU_ASILE_PREFECTURE',
    'GESTIONNAIRE_GU_ASILE_PREFECTURE',
    'GESTIONNAIRE_ASILE_PREFECTURE',
    # "Gestionnaire de titres" is temporarily disabled => prevent admin pref from creating one
    # This is necessary so we can deploy to production while TTE consumption is not finished.
    # We wish we could do proper Feature Flipping, but we're still discussing with DSIC to find how.
    # TODO: uncomment this role when feature will be activated (TTE should be released on April 10th, 2017)
    # 'GESTIONNAIRE_DE_TITRES'
  ]

  .directive 'habilitationDirective', ->
    restrict: 'E'
    templateUrl: 'scripts/xin/habilitations/habilitation.html'
    controller: 'habilitationController'
    scope:
      accreditation: '=?'

  .controller 'habilitationController', ($scope, Backend, session, SETTINGS,
                                         ADMINISTRATEUR_NATIONAL_CREATES_ROLES,
                                         ADMINISTRATEUR_PREFECTURE_CREATE_ROLES,
                                         DelayedEvent) ->
    $scope.site = {}
    $scope.role = undefined
    $scope.settingsSites = SETTINGS.SITES

    # Bind fin_validite
    $scope.$watch 'accreditation.data.fin_validite', (value) ->
      $scope.accreditation_inactif = false
      if value? and value != ""
        now = moment()
        fin_validite = moment(value)
        if fin_validite < now
          $scope.accreditation_inactif = true

    # Bind site
    delayedFilter = new DelayedEvent(500)
    $scope.$watch 'accreditation.data.site_affecte', (siteId) ->
      delayedFilter.triggerEvent ->
        if siteId? and siteId != ""
          Backend.one('sites/' + siteId).get().then(
            (site) ->
              $scope.site = site
          )
        else
          $scope.site = {}

    # Bind roles
    session.getUserPromise().then(
      (user) ->
        $scope.role = $scope.accreditation.data.role
        $scope.$watch 'role', (value) ->
          $scope.accreditation.data.role = value
          $scope.accreditation.system_account = undefined
          if ['SYSTEME_INEREC', 'SYSTEME_AGDREF', 'SYSTEME_DNA'].indexOf(value) > -1
            $scope.accreditation.system_account = true

        # Define which roles could be selected
        $scope.selectRoles = []
        if $scope.accreditation.mode != 'create'
          $scope.selectRoles.push({id: $scope.accreditation.data.role, libelle: SETTINGS.ROLES[$scope.accreditation.data.role]})
          if $scope.accreditation.data.site_affecte
            $scope.site_associated = true
            $scope.siteLocked = true
            $scope.sites_url = 'sites?fq=doc_id:' +  $scope.accreditation.data.site_affecte.id
        else
          for value, text of SETTINGS.ROLES
            if ['ADMINISTRATEUR', 'SUPPORT_NATIONAL'].indexOf(user.role) > -1
              $scope.selectRoles.push({id: value, libelle: text})
            else if user.role ==  'ADMINISTRATEUR_NATIONAL'
              if value in ADMINISTRATEUR_NATIONAL_CREATES_ROLES
                $scope.selectRoles.push({id: value, libelle: text})
            else if user.role == 'ADMINISTRATEUR_PA'
              if ['RESPONSABLE_PA', 'GESTIONNAIRE_PA'].indexOf(value) > -1
                $scope.selectRoles.push({id: value, libelle: text})
            else if user.role == 'ADMINISTRATEUR_PREFECTURE'
              if value in ADMINISTRATEUR_PREFECTURE_CREATE_ROLES
                $scope.selectRoles.push({id: value, libelle: text})
            else if user.role == 'ADMINISTRATEUR_DT_OFII'
              if ['RESPONSABLE_GU_DT_OFII', 'GESTIONNAIRE_GU_DT_OFII'].indexOf(value) > -1
                $scope.selectRoles.push({id: value, libelle: text})

          if user.role == 'ADMINISTRATEUR_PA'
            $scope.site_associated = true
            $scope.siteLocked = true
            $scope.sites_url = 'sites?fq=doc_id:' + user.site_affecte.id
            $scope.accreditation.data.site_affecte = user.site_affecte.id
          else if user.role == 'ADMINISTRATEUR_PREFECTURE'
            $scope.$watch 'role', (value) ->
              if value in ['GESTIONNAIRE_GU_ASILE_PREFECTURE', 'RESPONSABLE_GU_ASILE_PREFECTURE']
                $scope.site_associated = true
                $scope.siteLocked = false
                $scope.sites_url = 'sites?fq=autorite_rattachement_r:' + user.site_affecte.id
              else if value in ['GESTIONNAIRE_ASILE_PREFECTURE', 'GESTIONNAIRE_DE_TITRES']
                $scope.site_associated = true
                $scope.siteLocked = true
                $scope.sites_url = 'sites?fq=doc_id:' + user.site_affecte.id
                $scope.accreditation.data.site_affecte = user.site_affecte.id
              else
                $scope.site_associated = false
                $scope.siteLocked = false
                $scope.sites_url = ''
                $scope.accreditation.data.site_affecte = null
          else if user.role == 'ADMINISTRATEUR_DT_OFII'
            $scope.$watch 'role', (value) ->
              if ['RESPONSABLE_GU_DT_OFII', 'GESTIONNAIRE_GU_DT_OFII'].indexOf(value) > -1
                $scope.site_associated = true
                $scope.siteLocked = false
                $scope.sites_url = 'sites?fq=autorite_rattachement_r:' + user.site_affecte.id
              else
                $scope.site_associated = false
                $scope.siteLocked = false
                $scope.sites_url = ''
                $scope.accreditation.data.site_affecte = null
          else if user.role == 'ADMINISTRATEUR_NATIONAL'
            $scope.$watch 'role', (value) ->
              if value == 'ADMINISTRATEUR_PA'
                $scope.site_associated = true
                $scope.siteLocked = false
                $scope.sites_url = 'sites?fq=type:StructureAccueil'
              else if ['ADMINISTRATEUR_PREFECTURE', 'ADMINISTRATEUR_DT_OFII'].indexOf(value) > -1
                $scope.site_associated = true
                $scope.sites_url = 'sites?fq=type:Prefecture'
              else if ['RESPONSABLE_ZONAL'].indexOf(value) > -1
                $scope.site_associated = true
                $scope.sites_url = 'sites?fq=type:EnsembleZonal'
              else
                $scope.site_associated = false
                $scope.sites_url = ''
    )
