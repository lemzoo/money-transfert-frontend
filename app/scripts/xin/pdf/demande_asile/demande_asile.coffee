'use strict'


angular.module('xin.pdf.demande_asile', [])
  .factory 'DemandeAsilePdf', ($filter, $q, Backend, SETTINGS, Pdf, is_minor) ->
    class DemandeAsilePdf extends Pdf
      constructor: (@_demande_asile, @_usager, @_droits, @_lieux_delivrances,
                    @_requalifications, @_localisations, @_portail) ->
        super
        @_PHOTO_WIDTH = 32
        @_PHOTO_HEIGHT = 33
        @_SITUATION_FAMILIALE =
          'CELIBATAIRE' : 'Célibataire'
          'DIVORCE' : 'Divorcé(e)'
          'MARIE' : 'Marié(e)'
          'CONCUBIN' : 'Concubin(e)'
          'SEPARE' : 'Séparé(e)'
          'VEUF' : 'Veuf(ve)'
          'PACSE' : 'Pacsé(e)'

      generate: (language = "") ->
        defer = $q.defer()
        usager_promises = []
        if @_usager.photo?
          promise = @addPhoto(@_usager, @_api_url+@_usager.photo._links.data)
          usager_promises.push(promise)
        $q.all(usager_promises).then(
          () =>
            @_pdf = @_newPdf()
            @_generate()
            defer.resolve()
          (error) ->
            defer.reject(error)
        )
        return defer.promise

      addPhoto: (usager, url) ->
        defer = $q.defer()
        @_convertImgToBase64URL(url).then(
          (img) =>
            @_addPhoto(usager, img.dataURL, img.width, img.height)
            defer.resolve()
          (error) ->
            defer.reject(error)
        )
        return defer.promise

      _generate: () ->
        @_pdf.setFontSize(18)
        @_pdf.setFontType('bold')
        text = "Demande d'asile #{@_demande_asile.id}"
        width = @_ptTomm(@_pdf.getTextDimensions(text).w)
        @_pdf.text(105-width/2, 25, text)

        # Positions
        x = 20
        y = 40

        # Informations de demande d'asile
        title = "Informations de demande d'asile"
        fields = [
          @_getText("Statut", SETTINGS.DA_STATUT[@_demande_asile.statut])
          @_getText("N° Etranger", @_usager.identifiant_agdref)
          @_getText("N° Eurodac", @_demande_asile.usager_identifiant_eurodac)
          @_getDate("Date de demande", @_demande_asile.date_demande)
          @_getText("Type de demande", @_demande_asile.type_demande)
          @_getText("Orgnanisme à l'origine du type de la demande", @_demande_asile.acteur_type_demande)
        ]
        if @_demande_asile.type_demande == 'REEXAMEN'
          fields.push(@_getText("Numéro du réexamen", @_demande_asile.numero_reexamen))
        fields = fields.concat([
          @_getText("Décision sur délivrance de l'attestation", @_demande_asile.decision_sur_attestation)
          @_getDate("Date de décision sur attestation", @_demande_asile.date_decision_sur_attestation)
          @_getText("Type de procédure", @_demande_asile.procedure.type)
          @_getText("Motif de qualification", @_demande_asile.procedure.motif_qualification)
          @_getDate("Date de notification", @_demande_asile.procedure.date_notification)
          @_getText("Organisme à l'origine de la qualification", SETTINGS.ORGANISME_QUALIFICATEUR[@_demande_asile.procedure.acteur])
          @_getDate("Date d'arrivée en France", @_demande_asile.date_entree_en_france,
                    @_demande_asile.date_entree_en_france_approximative)
          @_getDate("Date de départ du pays d'origine", @_demande_asile.date_depart,
                    @_demande_asile.date_depart_approximative)
          @_getText("Condition d'entrée en France", @_demande_asile.condition_entree_france)
          @_getText("Visa", @_demande_asile.visa)
          @_getText("Conditions exceptionnelles d'accueil", @_demande_asile.conditions_exceptionnelles_accueil)
        ])
        if @_demande_asile.conditions_exceptionnelles_accueil
          fields.push(@_getText("Motif conditions exceptionnelles d'accueil", @_demande_asile.motif_conditions_exceptionnelles_accueil))
        if @_demande_asile.pays_traverses?.length
          fields.push(@_getText("Pays traversés", ''))
          for pays in @_demande_asile.pays_traverses
            fields = fields.concat([
              @_getLine()
              @_getSubSubtitle("#{pays.pays.libelle}")
              @_getDate("Date d'entrée", pays.date_entree, pays.date_entree_approximative)
              @_getDate("Date de sortie", pays.date_sortie, pays.date_sortie_approximative)
              @_getText("Moyen de transport", pays.condition_franchissement)
              @_getText("Condition de franchissement", pays.condition_franchissement)
              @_getLine()
            ])
        else
          fields.push(@_getText("Pays traversés", "Aucun pays traversé"))
        y = @_addThumbnail(title, fields, x, y)

        # Introduction OFPRA
        if @_demande_asile.identifiant_inerec?
          title = "Introduction OFPRA"
          fields = [
            @_getText("Identifiant INEREC", @_demande_asile.identifiant_inerec)
            @_getDate("Date d'introduction d'OFPRA", @_demande_asile.date_introduction_ofpra)
          ]
          y = @_addThumbnail(title, fields, x, y)

        # Informations DUBLIN
        if @_demande_asile.dublin?
          title = "Informations DUBLIN"
          fields = [
            @_getDate("Date de demande à l'état membre", @_demande_asile.dublin.date_demande_EM)
            @_getDate("Date de réponse de l'état membre", @_demande_asile.dublin.date_reponse_EM)
            @_getText("Etats membres", @_demande_asile.dublin.EM?.libelle)
            @_getText("Réponse de l'état Membre", @_demande_asile.dublin.reponse_EM)
            @_getDate("Date de décision", @_demande_asile.dublin.date_decision)
            @_getText("Exécution", @_demande_asile.dublin.execution)
            @_getDate("Date exécution", @_demande_asile.dublin.date_execution)
            @_getText("Délai départ volontaire", @_demande_asile.dublin.delai_depart_volontaire)
            @_getText("Contentieux", @_demande_asile.dublin.date_reponse_EM)
            @_getText("Décision contentieux", @_demande_asile.dublin.decision_contentieux)
            @_getDate("Date de signalement de la fuite", @_demande_asile.dublin.date_signalement_fuite)
          ]
          y = @_addThumbnail(title, fields, x, y)

        # Historique des requalifications
        if @_requalifications
          title = "Historique des requalifications"
          fields = []
          for requal in @_demande_asile.procedure.requalifications
            fields = fields.concat([
              @_getLine()
              @_getDate("Date de qualification", requal.date)
              @_getDate("Date de notification", requal.date_notification)
              @_getText("Organisme qualificateur", requal.ancien_acteur)
              @_getText("Type", requal.ancien_type)
              @_getText("Motif de qualification", requal.ancien_motif_qualification)
              @_getLine()
            ])
          y = @_addThumbnail(title, fields, x, y)

        # Décisions définitives
        if @_demande_asile.decisions_definitives
          title = "Décisions définitives"
          fields = []
          for decision in @_demande_asile.decisions_definitives
            nature = "#{SETTINGS.DECISION_DEFINITIVE_RESULTAT[decision.entite][decision.nature]} -
                      #{SETTINGS.DECISION_DEFINITIVE_NATURE[decision.entite][decision.nature]}"
            fields = fields.concat([
              @_getLine()
              @_getText("Nature", nature)
              @_getText("Pays exclus", decision.pays_exclus?.libelle)
              @_getText("Numéro skipper", decision.numero_skipper)
              @_getText("Origine de la décision", decision.entite)
              @_getDate("Date de la décision", decision.date)
              @_getDate("Date de premier accord", decision.date_premier_accord)
              @_getDate("Date de notification", decision.date_notification)
              @_getLine()
            ])
          y = @_addThumbnail(title, fields, x, y)

        # Recevabilité
        if (@_demande_asile.type_demande == 'REEXAMEN' and
            @_demande_asile.recevabilites and @_demande_asile.recevabilites.length)
          title = "Recevabilité - Irrecevabilité"
          fields = []
          for recevabilite in @_demande_asile.recevabilites
            fields = fields.concat([
              @_getLine()
              @_getText("Nature de la décision",
                        if recevabilite.recevabilite == 'M' then 'Recevable' else 'Irrecevable')
              @_getDate("Date de qualification", recevabilite.date_qualification)
              @_getDate("Date de notification", recevabilite.date_notification)
              @_getLine()
            ])
          y = @_addThumbnail(title, fields, x, y)

        # Informations de l'usager
        title = "Informations de l'usager"
        fields = []
        # DROITS
        if @_demande_asile?.statut? != 'PRETE_EDITION_ATTESTATION' and @_droits?.length
          fields.push(@_getSubtitle("Droits"))
          for droit in @_droits
            fields = fields.concat([
              @_getLine()
              @_getText("Type d'attestation", SETTINGS.SOUS_TYPE_DOCUMENT[droit.sous_type_document])
              @_getDate("Date de début de validité", droit.date_debut_validite)
              @_getDate("Date de fin de validité", droit.date_fin_validite)
            ])
            for support in droit.supports
              subsubtitle = "N° #{support.numero_serie} délivré le #{$filter('date')(support.date_delivrance, 'shortDate')} à #{@_lieux_delivrances[support.lieu_delivrance.id]}"
              if support.motif_annulation
                subsubtitle = "#{subsubtitle}[Annulé pour #{support.motif_annulation}]"
              fields.push(@_getSubSubtitle(subsubtitle))
            fields.push(@_getLine())
        # IDENTITE
        fields = fields.concat([
          @_getSubtitle("Identité")
          @_getPhoto(@_usager.photoPdf.base64Img)
          @_getText("N° usager", @_usager.id)
          @_getText("Numéro étranger", @_usager.identifiant_agdref)
          @_getText("Identifiant DN@", @_usager.identifiant_dna)
          @_getText("Nom", @_usager.nom)
          @_getText("Nom d'usage", @_usager.nom_usage)
          @_getText("Prénom(s)", @_usager.prenoms.toString().replace(/,/g, ", "))
          @_getText("Sexe", if @_usager.sexe == 'M' then 'Masculin' else 'Féminin')
        ])
        # INFORMATION NAISSANCE
        fields = fields.concat([
          @_getSubtitle("Informations de naissance")
          @_getDate("Date de naissance", @_usager.date_naissance,
                    @_usager.date_naissance_approximative)
          @_getText("Ville de naissance", @_usager.ville_naissance)
          @_getText("Pays de naissance", @_usager.pays_naissance.libelle)
          @_getText("Nationalité", @_usager.nationalites[0].libelle)
          @_getText("Nom du père", @_usager.nom_pere)
          @_getText("Prénom du père", @_usager.prenom_pere)
          @_getText("Nom de la mère", @_usager.nom_mere)
          @_getText("Prénom de la mère", @_usager.prenom_mere)
        ])
        # INFORMATION MINEUR
        if @_usager.demandeur and is_minor(@_usager.date_naissance)
          fields = fields.concat([
            @_getText("Profil de demande",
              if @_usager.type_usager == 'usager1' then 'Mineur isolé' else 'Mineur accompagnant')
            @_getText("Nom du représentant", @_usager.representant_legal_nom)
            @_getText("Prénom du représentant", @_usager.representant_legal_prenom)
            @_getText("Personne morale", @_usager.representant_legal_personne_morale)
          ])
          if @_usager.representant_legal_personne_morale
            fields.push(@_getText("Désignation de la personne morale", @_usager.representant_legal_personne_morale_designation))
        # INFORMATION COMPLEMENTAIRE
        fields = fields.concat([
          @_getSubtitle("Informations complémentaires")
          @_getText("Situation familiale", @_SITUATION_FAMILIALE[@_usager.situation_familiale])
          @_getText("Langue(s) comprise(s)",
            (elt.libelle for elt in @_usager.langues).toString().replace(/,/g, ", "))
          @_getText("Langue d'audition à l'OFPRA", @_usager.langues_audition_OFPRA?[0].libelle)
          @_getText("Téléphone", @_usager.telephone)
          @_getText("Email", @_usager.email)
        ])
        # LOCALISATIONS
        fields.push(@_getSubtitle("Localisations"))
        # PARTENAIRES
        if @_localisations.dna.data? or @_localisations.agdref.data? or @_localisations.ofpra.data?
          fields.push(@_getSubSubtitle("Mise à jour de l'adresse par un partenaire"))
          for loc in @_localisations
            fields = fields.concat([
              @_getLine()
              @_getText("Organisme à l'origine de la mise à jour", loc.data.organisme_origine)
              @_getDate("Date de mise à jour", loc.data.date_maj)
              @_getText("Chez", loc.data.adresse.chez)
              @_getText("Complément", loc.data.adresse.complement)
              @_getText("Numéro de voie", loc.data.adresse.numero_voie)
              @_getText("Voie", loc.data.adresse.voie)
              @_getText("Ville", loc.data.adresse.ville)
              @_getText("Code Insee", loc.data.adresse.code_insee)
              @_getText("Code Postal", loc.data.adresse.code_postal)
              @_getText("Pays", loc.data.adresse.pays?.libelle)
              @_getLine()
            ])
        # ADRESSE
        fields = fields.concat([
          @_getSubSubtitle("Adresse")
          @_getText("Adresse inconnue", @_portail.adresse.adresse_inconnue)
        ])
        if not @_portail.adresse.adresse_inconnue
          fields = fields.concat([
            @_getText("Chez", @_portail.adresse.chez)
            @_getText("Complément", @_portail.adresse.complement)
            @_getText("Numéro de voie", @_portail.adresse.numero_voie)
            @_getText("Voie", @_portail.adresse.voie)
            @_getText("Ville", @_portail.adresse.ville)
            @_getText("Code Insee", @_portail.adresse.code_insee)
            @_getText("Code Postal", @_portail.adresse.code_postal)
            @_getText("Pays", @_portail.adresse.pays?.libelle)
          ])
        y = @_addThumbnail(title, fields, x, y)

      _checkEndPage: (marginTop, height) ->
        return marginTop + height > 272

      _getSubtitle: (value) ->
        return {"SUBTITLE": value}

      _getSubSubtitle: (value) ->
        return {"SUBSUBTITLE": value}

      _getLine: () ->
        return {"LINE": ''}

      _getPhoto: (value) ->
        return {"PHOTO": value}

      _getText: (key, value) ->
        if not value? then return {"EMPTY": ''}
        if typeof(value) == 'boolean'
          value = if value then 'Oui' else 'Non'
        return {"TEXT": "#{key}: #{value}"}

      _getDate: (key, value, approximatif=false) ->
        if not value? then return {"EMPTY": ''}
        value = $filter('date')(value, "shortDate")
        value = if approximatif then "#{value} (approximative)" else value
        return {"TEXT": "#{key}: #{value}"}

      _addThumbnail: (title, fields, left, top, right=190) ->
        # Write Thumbnail title
        @_pdf.setFontSize(14)
        @_pdf.setFontType('bold')
        dim = @_pdf.getTextDimensions(title)
        title_width = @_ptTomm(dim.w)
        @_pdf.text(left + 6, top + 2, title)
        @_pdf.line(left, top, left + 5, top)
        @_pdf.line(left + 10 + title_width, top, right, top)

        # Write Fields
        @_pdf.setFontSize(10)
        @_pdf.setFontType('normal')
        column = ((right - left) / 2)
        position =
          'left': left + 2
          'middle': left + column + 2
        pos = position['left']
        lines = 2

        for field in fields
          if @_checkEndPage(top, (lines * 5))
            # Write lines
            height = top + (lines * 5)
            # Left
            @_pdf.line(left, top, left, height)
            # Right
            @_pdf.line(right, top, right, height)
            @_pdf.addPage()
            @_currentPage++
            top = 25
            lines = 2

          if field['EMPTY']?
            continue
          else if field['SUBTITLE']?
            text = field['SUBTITLE']
            @_pdf.setFontSize(14)
            @_pdf.setFontType('bold')
            if pos isnt position['left']
              pos = position['left']
              lines += 1
            lines += 1
            @_pdf.text(pos, top + (lines * 5), text)
            lines += 1
            @_pdf.setFontSize(10)
            @_pdf.setFontType('normal')
          else if field['SUBSUBTITLE']?
            text = field['SUBSUBTITLE']
            @_pdf.setFontType('bold')
            if pos isnt position['left']
              pos = position['left']
              lines += 1
            @_pdf.text(pos, top + (lines * 5), text)
            lines += 1
            @_pdf.setFontType('normal')
          else if field['LINE']?
            if pos isnt position['left']
              pos = position['left']
              lines += 1
            @_pdf.line(left + 15, top + (lines * 5), right - 15, top + (lines * 5))
            lines += 1
          else if field['PHOTO']?
            if pos isnt position['left']
              pos = position['left']
              lines += 1
            @_pdf.rect(position['middle'] - (@_PHOTO_WIDTH / 2), top + (lines * 5),
                       @_PHOTO_WIDTH, @_PHOTO_HEIGHT)
            @_pdf.addImage(field['PHOTO'], 'PNG',
                           position['middle'] - (@_PHOTO_WIDTH / 2), top + (lines * 5),
                           @_PHOTO_WIDTH, @_PHOTO_HEIGHT)
            lines += 9
          else if field['TEXT']?
            text = field['TEXT']
            if pos is position['left']
              # Left Column
              @_pdf.text(pos, top + (lines * 5), text)
              # If long text, create new line.
              # Otherwise, try to write on right column
              if @_ptTomm(@_pdf.getTextDimensions(text).w) > column
                pos = position['left']
                lines += 1
              else
                pos = position['middle']
            else
              # Right Column
              # If long text, create new line
              if @_ptTomm(@_pdf.getTextDimensions(text).w) > column
                pos = position['left']
                lines += 1
              # Write text and create new line
              @_pdf.text(pos, top + (lines * 5), text)
              pos = position['left']
              lines += 1

        if pos is position['middle']
          # Create new line
          pos = position['left']
          lines += 1

        # Write lines
        height = top + (lines * 5)
        # Left
        @_pdf.line(left, top, left, height)
        # Right
        @_pdf.line(right, top, right, height)
        # Bottom
        @_pdf.line(left, height, right, height)

        # Return Bottom position
        return height + 7
