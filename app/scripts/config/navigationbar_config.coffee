'use strict'

angular.module('app.navigationbar_config', [])
  .constant 'NAVIGATIONBAR_CONFIG',
      "/accueil":
        elToActivate: '.nav-accueil'
        htmlToRender: 'Navigation'
      "/utilisateurs":
        elToActivate: '.nav-utilisateurs'
        htmlToRender: '<i class="fa fa-lg fa-users"></i> Utilisateurs'
      "/utilisateurs/:userId":
        elToActivate: '.nav-utilisateurs'
        htmlToRender: '<i class="fa fa-lg fa-users"></i> Utilisateurs'
      "/utilisateurs/nouvel-utilisateur":
        elToActivate: '.nav-utilisateurs'
        htmlToRender: '<i class="fa fa-lg fa-users"></i> Utilisateurs'
      "/profil":
        elToActivate: '.nav-utilisateurs'
        htmlToRender: '<i class="fa fa-lg fa-users"></i> Profil'
      "/sites":
        elToActivate: '.nav-sites'
        htmlToRender: '<i class="fa fa-lg fa-university"></i> Sites'
      "/sites/:siteId":
        elToActivate: '.nav-sites'
        htmlToRender: '<i class="fa fa-lg fa-university"></i> Sites'
      "/sites/nouveau-site":
        elToActivate: '.nav-sites'
        htmlToRender: '<i class="fa fa-lg fa-university"></i> Sites'
      "/orchestration-echanges":
        elToActivate: '.nav-webhooks'
        htmlToRender: '<i class="fa fa-lg fa-share-alt"></i> Orchestration des échanges'
      "/orchestration-echanges/:queueId":
        elToActivate: '.nav-webhooks'
        htmlToRender: '<i class="fa fa-lg fa-share-alt"></i> Orchestration des échanges'
      "/orchestration-echanges-rabbit":
        elToActivate: '.nav-webhooks-rabbit'
        htmlToRender: '<i class="fa fa-lg fa-share-alt"></i> Orchestration des échanges V2'
      "/orchestration-echanges-rabbit/:queueId":
        elToActivate: '.nav-webhooks-rabbit'
        htmlToRender: '<i class="fa fa-lg fa-share-alt"></i> Orchestration des échanges V2'
      "/parametrage":
        elToActivate: '.nav-parametrage'
        htmlToRender: '<i class="fa fa-lg fa-cog"></i> Paramétrage'
      "/plages-rdv":
        elToActivate: '.nav-plages-rdv'
        htmlToRender: '<i class="fa fa-lg fa-calendar"></i> Plages de rendez-vous'
      "/premier-accueil":
        elToActivate: '.nav-premier-accueil'
        htmlToRender: '<i class="fa fa-lg fa-folder-open-o"></i> Premier accueil'
      "/premier-accueil/:recueilDaId":
        elToActivate: '.nav-premier-accueil'
        htmlToRender: '<i class="fa fa-lg fa-folder-open-o"></i> Premier accueil'
      "/premier-accueil/:recueilDaId/rendez-vous":
        elToActivate: '.nav-premier-accueil'
        htmlToRender: '<i class="fa fa-lg fa-folder-open-o"></i> Premier accueil'
      "/premier-accueil/nouveau-recueil":
        elToActivate: '.nav-premier-accueil'
        htmlToRender: '<i class="fa fa-lg fa-folder-open-o"></i> Premier accueil'
      "/gu-enregistrement":
        elToActivate: '.nav-gu-enregistrement'
        htmlToRender: '<i class="fa fa-lg fa-camera-retro"></i> GU Enregistrement'
      "/gu-enregistrement/:recueilDaId":
        elToActivate: '.nav-gu-enregistrement'
        htmlToRender: '<i class="fa fa-lg fa-camera-retro"></i> GU Enregistrement'
      "/attestations":
        elToActivate: '.nav-attestations'
        htmlToRender: '<i class="fa fa-lg fa-print"></i> Edition d\'attestation'
      "/attestations/:demandeAsileId":
        elToActivate: '.nav-attestations'
        htmlToRender: '<i class="fa fa-lg fa-print"></i> Edition d\'attestation'
      "/demandes-asiles":
        elToActivate: '.nav-demandes-asiles'
        htmlToRender: '<i class="fa fa-lg fa-file-o"></i> Demandes d\'asile'
      "/demandes-asiles/:demandeAsileId":
        elToActivate: '.nav-demandes-asiles'
        htmlToRender: '<i class="fa fa-lg fa-file-o"></i> Demandes d\'asile'
      "/demandes-asiles/:demandeAsileId/attestation/:droitId":
        elToActivate: '.nav-demandes-asiles'
        htmlToRender: '<i class="fa fa-lg fa-file-o"></i> Demandes d\'asile'
      "/usagers":
        elToActivate: '.nav-usagers'
        htmlToRender: '<i class="fa fa-lg fa-users"></i> Usagers'
      "/usagers/:usagerId":
        elToActivate: '.nav-usagers'
        htmlToRender: '<i class="fa fa-lg fa-users"></i> Usagers'
      "/transfert-de-dossier":
        elToActivate: '.nav-transfert-de-dossier'
        htmlToRender: '<i class="fa fa-lg fa-reply-all"></i> Transfert de dossier'
      "/historique-telem-ofpra":
        elToActivate: '.nav-historique-telemofpra'
        htmlToRender: '<i class="fa fa-lg fa-eye"></i> Historique accès Telem Ofpra'
      "/extractions-base":
        elToActivate: '.nav-extractions-base'
        htmlToRender: '<i class="fa fa-lg fa-file-excel-o"></i> Extractions base de données'
      "/indicateurs-pilotage":
        elToActivate: '.nav-indicateurs-pilotage'
        htmlToRender: '<i class="fa fa-lg fa-file-excel-o"></i> Indicateurs de pilotage'
      "/indicateurs-pilotage/charge-spa":
        elToActivate: '.nav-indicateurs-pilotage'
        htmlToRender: '<i class="fa fa-lg fa-file-excel-o"></i> Indicateurs de pilotage'
      "/indicateurs-pilotage/charge-gu":
        elToActivate: '.nav-indicateurs-pilotage'
        htmlToRender: '<i class="fa fa-lg fa-file-excel-o"></i> Indicateurs de pilotage'
      "/indicateurs-pilotage/transferts-entrants":
        elToActivate: '.nav-indicateurs-pilotage'
        htmlToRender: '<i class="fa fa-lg fa-file-excel-o"></i> Indicateurs de pilotage'
      "/indicateurs-pilotage/prestation-spa":
        elToActivate: '.nav-indicateurs-pilotage'
        htmlToRender: '<i class="fa fa-lg fa-file-excel-o"></i> Indicateurs de pilotage'
      "/remise-titres":
        elToActivate: '.nav-remise-titres'
        htmlToRender: '<i class="fa fa-lg fa-id-card-o"></i> Remise de titres'
      "/aide":
        elToActivate: '.nav-utilisateurs'
        htmlToRender: '<i class="fa fa-info-circle"></i> Aide'
