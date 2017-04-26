'use strict'

angular.module('app.settings', [])
  .run (SETTINGS) ->
    # Must build this variable at runtime
    SETTINGS.API_BASE_URL = ""
    if SETTINGS.API_DOMAIN? and SETTINGS.API_DOMAIN != ""
      SETTINGS.API_BASE_URL = SETTINGS.API_DOMAIN
    else
      SETTINGS.API_BASE_URL = window.location.origin
    SETTINGS.API_URL = SETTINGS.API_BASE_URL + SETTINGS.API_URL_PREFIX
  .constant 'SETTINGS',
    DEFAULT_COUNTRY: 'FRA'
    API_DOMAIN: 'http://localhost:5000'
    FRONT_DOMAIN: 'http://localhost:9000'
    TELEM_OFPRA_URL: 'https://telemofpra.diplomatie.ader.gouv.fr/connexionGU-MI.aspx'
    TELEM_OFPRA_USER: 'GUICHUNI'
    API_URL_PREFIX: ''
    ETALAB_DOMAIN: 'https://api-adresse.data.gouv.fr/search/'
    BASE_TITLE: 'SIEF'
    PER_PAGE_DEFAULT: 12
    ORGANISME_QUALIFICATEUR:
      "OFPRA" : "OFPRA"
      "GUICHET_UNIQUE": "Préfecture"
      "PREFECTURE" : "Préfecture"
    TYPE_DOCUMENT:
      "ATTESTATION_DEMANDE_ASILE" : "Attestation de demande d'asile"
      "CARTE_SEJOUR_TEMPORAIRE" : "Carte de séjour temporaire"
      "DOCUMENT_CIRCULATION_MINEUR" : "Document de circulation pour mineur"
      "CARTE_RESIDENT" : "Carte de résident"
    SOUS_TYPE_DOCUMENT:
      "PREMIERE_DELIVRANCE" : "Première délivrance"
      "PREMIER_RENOUVELLEMENT" : "Premier renouvellement"
      "EN_RENOUVELLEMENT" : "En renouvellement"
    TYPE_PROCEDURE:
      "NORMALE" : "Normale"
      "ACCELEREE" : "Accélérée"
      "DUBLIN" : "DUBLIN"
    DA_STATUT:
      "PRETE_EDITION_ATTESTATION" : "Prête pour édition d'attestation"
      "EN_ATTENTE_INTRODUCTION_OFPRA" : "En attente d'introduction OFPRA"
      "EN_COURS_PROCEDURE_DUBLIN" : "En cours de procédure DUBLIN"
      "EN_COURS_INSTRUCTION_OFPRA" : "En cours d'instruction OFPRA"
      "DECISION_DEFINITIVE" : "Décision définitive"
      "FIN_PROCEDURE_DUBLIN" : "Fin de procédure DUBLIN"
      "FIN_PROCEDURE" : "Fin de procédure"
    ORIGINE_NOM:[
      'id' : 'EUROPE'
      'libelle' : 'Européenne'
    ,
      'id' : 'ARABE'
      'libelle' : 'Arabe'
    ,
      'id' : 'CHINOISE'
      'libelle' : 'Chinoise'
    ,
      'id' : 'TURQUE/AFRIQ'
      'libelle' : 'Turque/Africaine'
    ]
    SITUATION_FAMILIALE: [
      { "id": "CELIBATAIRE", "libelle": "Célibataire" },
      { "id": "DIVORCE", "libelle": "Divorcé(e)" },
      { "id": "MARIE", "libelle": "Marié(e)" },
      { "id": "CONCUBIN", "libelle": "Concubin(e)" },
      { "id": "SEPARE", "libelle": "Séparé(e)" },
      { "id": "VEUF", "libelle": "Veuf(ve)" },
      { "id": "PACSE", "libelle": "Pacsé(e)" }
    ]
    MOTIF_DELIVRANCE_ATTESTATION:
      "AUTRE": "Autre"
      "DEMANDE_NON_DILATOIRE": "Demande jugée non dilatoire par le préfet"
      "DEMANDE_IRRECEVABLE": "Demande irrecevable et destinée à faire obstacle à un éloignement (L.743-2 4°)"
      "DEUXIEME_DEMANDE_REEXAMEN": "Deuxième demande de réexamen ou réexamen ultérieur"
    DECISION_DEFINITIVE_NATURE:
      "OFPRA":
        "CL" : "Clôture"
        "CR" : "Réfugié statutaire"
        "DC" : "Décès"
        "DE" : "Désistement"
        "IR" : "Irrecevabilité non suivie de recours"
        "RJ" : "Rejet de la demande non suivi de recours"
        "TF" : "Transf.protect. Etr.vers Frce"
        "DS" : "Dessaisissement"
        "PS" : "Protection Subsidiaire"
        "PS1" : "Protection Subsidiaire de type 1"
        "PS2" : "Protection Subsidiaire de type 2"
      "CNDA":
        "IAM" : "Irrecevable absence de moyens"
        "IF" : "Irrecevable forclusion"
        "ILE" : "Irrecevable langue étrangère"
        "IND" : "Irrecevable nouvelle demande"
        "INR" : "Irrecevable recours non régul."
        "IR" : "Irrecevable"
        "IRR" : "Irrecevable recours en révisio"
        "NL" : "Non Lieu"
        "NLO" : "Non Lieu ordonnance"
        "RJ" : "Rejet"
        "NOR" : "Rejet par ordonnance"
        "ANP" : "Protec. Subsidiaire"
        "AN" : "Annulation"
        "ANT" : "Annulation d'un refus de transfert"
        "RJO" : "Rejet ordonnances nouvelles"
        "DS" : "Désistement"
        "DSO" : "Désistement ordonnance"
        "RDR" : "Exclusion"
        "RIC" : "Incompétence"
        "AI" : "Autre irrecevabilité"
        "NLE" : "Non Lieu en l'état"
        "PS1" : "Annulation Protec. Subsid. 1"
        "PS2" : "Annulation Protec. Subsid. 2"
    DECISION_DEFINITIVE_RESULTAT:
      "OFPRA":
        "CL" : "Rejet"
        "CR" : "Accord"
        "DC" : "Rejet"
        "DE" : "Rejet"
        "IR" : "Rejet"
        "RJ" : "Rejet"
        "TF" : "Accord"
        "DS" : "Rejet"
        "PS" : "Accord"
        "PS1" : "Accord"
        "PS2" : "Accord"
      "CNDA":
        "IAM" : "Rejet"
        "IF" : "Rejet"
        "ILE" : "Rejet"
        "IND" : "Rejet"
        "INR" : "Rejet"
        "IR" : "Rejet"
        "IRR" : "Rejet"
        "NL" : "Accord"
        "NLO" : "Accord"
        "RJ" : "Rejet"
        "NOR" : "Rejet"
        "ANP" : "Accord"
        "AN" : "Accord"
        "ANT" : "Accord"
        "RJO" : "Rejet"
        "DS" : "Rejet"
        "DSO" : "Rejet"
        "RDR" : "Rejet"
        "RIC" : "Rejet"
        "AI" : "Rejet"
        "NLE" : "Accord"
        "PS1" : "Accord"
        "PS2" : "Accord"
    QUALIFICATION:
      'ACCELEREE' : [
        'id' : '1C5'
        'libelle' : 'Détermination de la loi (723-2 I) : POS'
      ,
        'id' : 'REEX'
        'libelle' : 'Détermination de la loi (723-2 I) : Demande de réexamen'
      ,
        'id' : 'EMPR'
        'libelle' : 'Décision du préfet (L. 723-2 III) : Refus de donner ses empreintes'
      ,
        'id' : 'FREM'
        'libelle' : 'Décision du préfet (L. 723-2 III) : Fraude'
      ,
        'id' : 'TARD'
        'libelle' : 'Décision du préfet (L. 723-2 III) : Demande tardive'
      ,
        'id' : 'DILA'
        'libelle' : 'Décision du préfet (L. 723-2 III) : Demande dilatoire'
      ,
        'id' : 'MGOP'
        'libelle' : 'Décision du préfet (L. 723-2 III) : Menace grave à l’ordre public'
      ,
        'id' : 'AECD'
        'libelle' : 'Suite à échec procédure Dublin'
      ,
        'id' : 'AD171'
        'libelle' : 'Application de l’article 17.1 Dublin (ex : clause de souveraineté)'
      ,
        'id' : 'AD31'
        'libelle' : 'Application de l’article 3.1 Dublin (défaillances systématiques d’un Etat européen soumis au règlement)'
      ]
      'NORMALE' : [
        'id' : 'PNOR'
        'libelle' : 'Dès l’origine'
      ,
        'id' : 'NECD'
        'libelle' : 'Suite à échec procédure Dublin'
      ,
        'id' : 'ND171'
        'libelle' : 'Application de l’article 17.1 Dublin (ex : clause de souveraineté)'
      ,
        'id' : 'ND31'
        'libelle' : 'Application de l’article 3.1 Dublin (défaillances systématiques d’un Etat européen soumis au règlement)'
      ]
      'DUBLIN' : [
        'id' : 'BDS'
        'libelle' : 'Titulaire d’un titre de séjour ou d’un visa délivré par un autre EM'
      ,
        'id' : 'FRIF'
        'libelle' : 'Franchissement irrégulier d’une frontière'
      ,
        'id' : 'EAEA'
        'libelle' : 'Demandeur d’asile dans un autre EM'
      ,
        'id' : 'DU172'
        'libelle' : 'Application de l’article 17.2 Dublin (ex : clause humanitaire)'
      ,
        'id' : 'FAML'
        'libelle' : 'Procédure familiale (articles 8 à 11 Dublin)'
      ,
        'id' : 'DU16'
        'libelle' : 'Personne dépendante (article 16 Dublin)'
      ,
        'id' : 'MIE'
        'libelle' : 'Recherche famille mineur isolé (article 6 Dublin)'
      ]
    CONDITION_ENTREE_EN_FRANCE: [
      'id' : 'REGULIERE'
      'libelle' : 'Régulière'
    ,
      'id' : 'IRREGULIERE'
      'libelle' : 'Irrégulière'
    ]
    CONDITIONS_EXCEPTIONNELLES_ACCUEIL: [
      'id' : 'VISA_D_ASILE'
      'libelle' : 'Visa D Asile'
    ,
      'id' : 'REINSTALLATION'
      'libelle' : 'Réinstallation'
    ,
      'id' : 'RELOCALISATION'
      'libelle' : 'Relocalisation'
    ,
      'id' : 'CAO'
      'libelle' : "CAO (centre d'accueil et d'orientation)"
    ]
    ATTESTATION_LABEL:
      'PREMIERE_DELIVRANCE' : 'Première délivrance'
      'PREMIER_RENOUVELLEMENT' : 'Premier renouvellement'
      'EN_RENOUVELLEMENT' : 'En renouvellement'
    SITES:
      'StructureAccueil': 'Structure d\'accueil'
      'GU': 'Guichet Unique'
      'Prefecture': 'Préfecture'
      'EnsembleZonal': 'Ensemble Zonal'
    ROLES:
      'ADMINISTRATEUR': 'Administrateur'
      'ADMINISTRATEUR_NATIONAL': 'Administrateur national'
      'ADMINISTRATEUR_PA' : 'Administrateur premier accueil'
      'ADMINISTRATEUR_PREFECTURE' : 'Administrateur préfecture'
      'ADMINISTRATEUR_DT_OFII' : 'Administrateur DT Ofii'
      'EXTRACTEUR': 'Responsable extractions'
      'RESPONSABLE_NATIONAL' : 'Responsable national'
      'SUPPORT_NATIONAL' : 'Support national'
      'RESPONSABLE_ZONAL': 'Responsable zonal'
      'SUPERVISEUR_ECHANGES' : 'Superviseur des échanges'
      'RESPONSABLE_PA' : 'Responsable Premier accueil'
      'GESTIONNAIRE_PA' : 'Gestionnaire Premier accueil'
      'GESTIONNAIRE_NATIONAL' : 'Gestionnaire national'
      'RESPONSABLE_GU_ASILE_PREFECTURE' : 'Responsable GU Asile préfecture'
      'GESTIONNAIRE_GU_ASILE_PREFECTURE' : 'Gestionnaire GU Asile préfecture'
      'GESTIONNAIRE_ASILE_PREFECTURE' : 'Gestionnaire asile préfecture'
      'GESTIONNAIRE_DE_TITRES' : 'Gestionnaire de titres'
      'RESPONSABLE_GU_DT_OFII' : 'Responsable GU DT Ofii'
      'GESTIONNAIRE_GU_DT_OFII' : 'Gestionnaire GU DT Ofii'
      'SYSTEME_INEREC' : 'Système INEREC'
      'SYSTEME_AGDREF' : 'Système AGDREF'
      'SYSTEME_DNA' : 'Système DN@'
    PROFIL_DEMANDE:
      'ADULTE_ISOLE': 'Majeur isolé'
      'FAMILLE': 'Famille'
      'MINEUR_ISOLE': 'Mineur isolé'
      'MINEUR_ACCOMPAGNANT': 'Mineur accompagnant'
    RECUEIL_STATUT:
      'BROUILLON': "Brouillon"
      'PA_REALISE': "Premier accueil réalisé"
      'DEMANDEURS_IDENTIFIES': "N° étranger attribué"
      'EXPLOITE': "Demande d'asile enregistrée"
      'ANNULE': "Recueil annulé"
    TYPE_DEMANDE: [
      'id': 'PREMIERE_DEMANDE_ASILE'
      'libelle': "Première demande d'asile"
    ,
      'id': 'REEXAMEN'
      'libelle': "Réexamen"
    ]
    PERMISSIONS:
      'ADMINISTRATEUR': [
        'creer_utilisateur',
        'modifier_utilisateur',
        '/utilisateurs',
        '/utilisateurs/:userId',
        '/utilisateurs/nouvel-utilisateur',
        '/sites',
        '/sites/nouveau-site',
        '/sites/:siteId',
        'creer_site',
        'modifier_site',
        'fermer_site',
        '/orchestration-echanges',
        '/orchestration-echanges/:queueId',
        '/orchestration-echanges/:queueId/nouvel-evenement',
        '/orchestration-echanges/:queueId/:eventId',
        'creer_webhook',
        'modifier_webhook',
        '/parametrage',
        '/historique-telem-ofpra',
        '/orchestration-echanges-rabbit',
        '/orchestration-echanges-rabbit/:queueId',
        '/orchestration-echanges-rabbit/:queueId/nouvel-evenement',
        '/orchestration-echanges-rabbit/:queueId/:eventId',
        'creer_webhook_rabbit',
        'modifier_webhook_rabbit',
      ],
      'SUPPORT_NATIONAL': [
        '/plages-rdv',
        '/utilisateurs',
        '/utilisateurs/:userId',
        '/sites',
        '/sites/:siteId',
        '/premier-accueil',
        '/premier-accueil/:recueilDaId',
        '/premier-accueil/:recueilDaId/impression',
        '/gu-enregistrement',
        '/gu-enregistrement/:recueilDaId',
        '/gu-enregistrement/:recueilDaId/convocation',
        '/attestations',
        '/attestations/:demandeAsileId',
        '/demandes-asiles',
        '/demandes-asiles/:demandeAsileId',
        '/demandes-asiles/telemOfpra/:numeroInerec',
        '/demandes-asiles/:demandeAsileId/attestation/:droitId',
        '/usagers',
        '/usagers/:usagerId',
        '/historique-telem-ofpra'
      ],
      'ADMINISTRATEUR_NATIONAL': [
        'creer_utilisateur',
        'modifier_utilisateur',
        '/utilisateurs',
        '/utilisateurs/:userId',
        '/utilisateurs/nouvel-utilisateur',
        '/sites',
        '/sites/nouveau-site',
        '/sites/:siteId',
        'creer_site',
        'modifier_site',
        'fermer_site',
        '/orchestration-echanges',
        '/orchestration-echanges/:queueId',
        '/orchestration-echanges/:queueId/nouvel-evenement',
        '/orchestration-echanges/:queueId/:eventId'
        'creer_webhook',
        'modifier_webhook',
        '/parametrage',
        '/historique-telem-ofpra',
        '/orchestration-echanges-rabbit',
        '/orchestration-echanges-rabbit/:queueId',
        '/orchestration-echanges-rabbit/:queueId/nouvel-evenement',
        '/orchestration-echanges-rabbit/:queueId/:eventId',
        'creer_webhook_rabbit',
        'modifier_webhook_rabbit',
      ],
      'RESPONSABLE_NATIONAL': [
        '/extractions-base',
        'export-usagers',
        'export-sites',
        'export-recueils_da',
        'export-demandes_asile',
        'export-droits',
        '/indicateurs-pilotage'
      ],
      'EXTRACTEUR': [
        '/extractions-base',
        'export-conditions_exceptionnelles_accueil',
        'export-demandes_en_attente_introduction_ofpra'
      ]
      'RESPONSABLE_ZONAL': [
        '/indicateurs-pilotage'
      ],
      'SUPERVISEUR_ECHANGES': [
        '/orchestration-echanges',
        '/orchestration-echanges/:queueId',
        '/orchestration-echanges/:queueId/nouvel-evenement',
        '/orchestration-echanges/:queueId/:eventId'
      ],
      'ADMINISTRATEUR_PA': [
        'creer_utilisateur',
        'modifier_utilisateur',
        '/utilisateurs',
        '/utilisateurs/:userId',
        '/utilisateurs/nouvel-utilisateur'
      ],
      'ADMINISTRATEUR_PREFECTURE': [
        'creer_utilisateur',
        'modifier_utilisateur',
        '/utilisateurs',
        '/utilisateurs/:userId',
        '/utilisateurs/nouvel-utilisateur'
      ],
      'ADMINISTRATEUR_DT_OFII': [
        'creer_utilisateur',
        'modifier_utilisateur',
        '/utilisateurs',
        '/utilisateurs/:userId',
        '/utilisateurs/nouvel-utilisateur'
      ],
      'GESTIONNAIRE_PA' : [
        '/premier-accueil',
        '/premier-accueil/:recueilDaId',
        '/premier-accueil/:recueilDaId/rendez-vous',
        '/premier-accueil/:recueilDaId/impression',
        '/premier-accueil/:recueilDaId/prendre-rendez-vous',
        'creer_recueil',
        'modifier_recueil'
      ],
      'RESPONSABLE_PA' : [
        '/premier-accueil',
        '/premier-accueil/:recueilDaId',
        '/premier-accueil/:recueilDaId/rendez-vous',
        '/premier-accueil/:recueilDaId/impression',
        '/premier-accueil/:recueilDaId/prendre-rendez-vous',
        'creer_recueil',
        'modifier_recueil'
      ],
      'GESTIONNAIRE_NATIONAL' : [
        '/gu-enregistrement',
        '/gu-enregistrement/:recueilDaId',
        '/gu-enregistrement/:recueilDaId/convocation',
        '/usagers',
        '/usagers/:usagerId',
        '/demandes-asiles',
        '/demandes-asiles/:demandeAsileId',
        '/indicateurs-pilotage'
      ],
      'RESPONSABLE_GU_ASILE_PREFECTURE': [
        '/plages-rdv',
        '/gu-enregistrement',
        '/gu-enregistrement/:recueilDaId',
        '/gu-enregistrement/:recueilDaId/rendez-vous',
        '/gu-enregistrement/:recueilDaId/convocation',
        'modifier_gu-enregistrement',
        '/attestations',
        '/attestations/:demandeAsileId',
        '/demandes-asiles',
        '/demandes-asiles/:demandeAsileId',
        '/demandes-asiles/telemOfpra/:numeroInerec',
        '/demandes-asiles/:demandeAsileId/attestation/:droitId',
        'modifier_da',
        '/usagers',
        '/usagers/:usagerId',
        'modifier_usager',
        '/transfert-de-dossier',
        '/indicateurs-pilotage'
      ],
      'RESPONSABLE_GU_DT_OFII': [
        '/plages-rdv',
        '/gu-enregistrement',
        '/gu-enregistrement/:recueilDaId',
        '/gu-enregistrement/:recueilDaId/convocation',
        '/indicateurs-pilotage'
      ],
      'GESTIONNAIRE_GU_ASILE_PREFECTURE': [
        '/gu-enregistrement',
        '/gu-enregistrement/:recueilDaId',
        '/gu-enregistrement/:recueilDaId/rendez-vous',
        '/gu-enregistrement/:recueilDaId/convocation',
        'modifier_gu-enregistrement',
        '/attestations',
        '/attestations/:demandeAsileId',
        '/demandes-asiles',
        '/demandes-asiles/:demandeAsileId',
        '/demandes-asiles/telemOfpra/:numeroInerec',
        '/demandes-asiles/:demandeAsileId/attestation/:droitId',
        'modifier_da',
        '/usagers',
        '/usagers/:usagerId',
        'modifier_usager',
        '/transfert-de-dossier'
      ],
      'GESTIONNAIRE_ASILE_PREFECTURE': [
        '/attestations',
        '/attestations/:demandeAsileId',
        '/demandes-asiles',
        '/demandes-asiles/:demandeAsileId',
        '/demandes-asiles/telemOfpra/:numeroInerec',
        '/demandes-asiles/:demandeAsileId/attestation/:droitId',
        'modifier_da',
        '/usagers',
        '/usagers/:usagerId',
        'modifier_usager',
        '/transfert-de-dossier',
        '/indicateurs-pilotage'
      ],
      'GESTIONNAIRE_DE_TITRES': [
        '/remise-titres'
      ],
      'GESTIONNAIRE_GU_DT_OFII': [
        '/gu-enregistrement',
        '/gu-enregistrement/:recueilDaId',
        '/gu-enregistrement/:recueilDaId/convocation'
      ]
    FILENAME_GUIDE : {
      'demo_all_only.pdf': ['*'],
      'demo_admin_only.pdf': ['ADMINISTRATEUR'],
      'demo_gu_asile_pref_only.pdf': ['GESTIONNAIRE_GU_ASILE_PREFECTURE']
      'demo_gu_asile_pref_and_admin.pdf': ['GESTIONNAIRE_ASILE_PREFECTURE', 'ADMINISTRATEUR']
    },
    FEATURE_FLIPPING: {
      'menu_aide': false
      'broker_rabbit': true
    }
