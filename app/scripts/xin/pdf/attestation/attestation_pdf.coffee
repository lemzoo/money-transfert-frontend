'use strict'


angular.module('xin.pdf.attestation', [])
  .factory 'AttestationPdf', ($filter, $q, Pdf, SETTINGS) ->
    class AttestationPdf extends Pdf
      constructor: (@usager, @isMinor, @demande_asile, @lieu_delivrance,
                    @date_delivrance, @droit, @attestation_label, @is_duplicata,
                    @callback) ->
        super

      generate: (language = "") ->
        defer = $q.defer()
        usager_promises = []
        if @usager.photo?
          promise = @addPhoto(@usager, @_api_url+@usager.photo._links.data)
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
        lineHeight = 2.5
        blankLineHeight = 2
        @_pdf.setFont("helvetica")

        # Titre
        margin = 90
        @_pdf.setFontSize(13)
        @_pdf.setTextColor(0, 0, 0)
        text = "ATTESTATION DE DEMANDE D'ASILE"
        dim = @_pdf.getTextDimensions(text)
        margin = 95.5
        @_pdf.text((210-dim.w*25.4/72)/2, margin, text)
        margin += @_ptTomm(dim.h)
        text = "PROCEDURE #{@demande_asile.procedure.type}"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text((210-dim.w*25.4/72)/2, margin, text)
        margin += @_ptTomm(dim.h)
        if @demande_asile.type_demande?
          text = "#{@demande_asile.type_demande}"
          for type_demande in SETTINGS.TYPE_DEMANDE
            if type_demande.id == @demande_asile.type_demande
              text = type_demande.libelle
              break
          dim = @_pdf.getTextDimensions(text)
          @_pdf.text((210-dim.w*25.4/72)/2, margin, text)
          margin += @_ptTomm(dim.h)
        margin = 112.2

        # Font to normal
        @_pdf.setFontStyle("normal")
        @_pdf.setTextColor(0, 0, 0)
        @_pdf.setFontSize(10)

        # Signature du titulaire
        @_pdf.text(150, margin+10, "Signature du titulaire")

        # Usager
        text = "Identifiant : #{@usager.identifiant_agdref}"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += @_ptTomm(dim.h)+lineHeight
        text = "Nom : #{@usager.nom}"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += @_ptTomm(dim.h)+lineHeight
        text = "Nom d'usage : #{@usager.nom_usage or ''}"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += @_ptTomm(dim.h)+lineHeight
        # prénoms
        text = "Prénoms : #{@usager.prenoms.toString().replace(/,/g, ", ")}"
        lines = @_pdf.splitTextToSize(text, 110)
        @_pdf.text(20, margin, lines)
        margin += lineHeight+3.8*lines.length
        # sexe
        sexe = ""
        if @usager.sexe == 'M'
          sexe = "Masculin"
        else if @usager.sexe == 'F'
          sexe = "Féminin"
        text = "Sexe : #{sexe}"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += @_ptTomm(dim.h)+3*lineHeight

        situationFamilialeCorr =
          'CELIBATAIRE' : 'Célibataire'
          'DIVORCE' : 'Divorcé(e)'
          'MARIE' : 'Marié(e)'
          'CONCUBIN' : 'Concubin(e)'
          'SEPARE' : 'Séparé(e)'
          'VEUF' : 'Veuf(ve)'
          'PACSE' : 'Pacsé(e)'

        text = "Situation familiale : " + situationFamilialeCorr[@usager.situation_familiale]
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += @_ptTomm(dim.h)+lineHeight
        text = "Né(e) le : #{$filter('xinDate')(@usager.date_naissance, 'shortDate', '+0000')}"
        text += " à #{@usager.ville_naissance}, #{@usager.pays_naissance.libelle or ''}"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += @_ptTomm(dim.h)+lineHeight
        text = "Nationalité : #{@usager.nationalites[0].libelle or ''}"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += @_ptTomm(dim.h)+lineHeight
        if @isMinor
          text = "Mineur"
          dim = @_pdf.getTextDimensions(text)
          @_pdf.text(20, margin, text)
          margin += @_ptTomm(dim.h)+lineHeight
          text = "Représentant légal : "
          if @usager.representant_legal_nom?
            text += @usager.representant_legal_nom + ", "
          if @usager.representant_legal_prenom?
            text += @usager.representant_legal_prenom
            if @usager.representant_legal_personne_morale_designation?
              text += ", "
          if @usager.representant_legal_personne_morale_designation?
            text += @usager.representant_legal_personne_morale_designation
          dim = @_pdf.getTextDimensions(text)
          @_pdf.text(20, margin, text)
          margin += @_ptTomm(dim.h)+lineHeight

        else
            text = ""
            @_pdf.text(20, margin, text)
            margin += blankLineHeight+lineHeight
            @_pdf.text(20, margin, text)
            margin += blankLineHeight+lineHeight
            @_pdf.text(20, margin, text)
            margin += blankLineHeight+lineHeight
        text = "Adresse :"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += lineHeight + @_ptTomm(dim.h)
        marginEnd = margin

        text = []
        if @usager.localisation.adresse.complement?
          text.push("#{@usager.localisation.adresse.complement}")
          marginEnd += 3.5
        text.push("#{@usager.localisation.adresse.numero_voie or ''} #{@usager.localisation.adresse.voie or ''}")
        marginEnd += 3.5
        text.push("#{@usager.localisation.adresse.code_postal or ''} #{@usager.localisation.adresse.ville or ''}")
        marginEnd += 3.5
        @_pdf.text(25, margin, text)
        margin = marginEnd+4

        text = "Chez :"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += @_ptTomm(dim.h)+lineHeight
        text = "#{@usager.localisation.adresse.chez or ''}"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(25, margin, text)
        margin += @_ptTomm(dim.h)+lineHeight

        # Condition entrée en France
        if @demande_asile.conditions_exceptionnelles_accueil and
           @demande_asile.motif_conditions_exceptionnelles_accueil in ["VISA_D_ASILE", "REINSTALLATION", "RELOCALISATION", "CAO"]
          text = "Conditions d'entrée en France : "
          if @demande_asile.motif_conditions_exceptionnelles_accueil == "VISA_D_ASILE"
            text += "Titulaire d'un visa au titre de l'asile"
          else if @demande_asile.motif_conditions_exceptionnelles_accueil == "REINSTALLATION"
            text += "Réinstallation"
          else if @demande_asile.motif_conditions_exceptionnelles_accueil == "RELOCALISATION"
            text += "Relocalisation"
          else if @demande_asile.motif_conditions_exceptionnelles_accueil == "CAO"
            text += "Centre d'Accueil et d'Orientation (CAO)"
          dim = @_pdf.getTextDimensions(text)
          @_pdf.text(20, margin, text)
          margin += @_ptTomm(dim.h)+2*lineHeight

        # Cachet
        @_pdf.text(130, margin, "Cachet et signature de l'autorité")

        # Autorité
        text = "Délivrée par : #{@lieu_delivrance}"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += @_ptTomm(dim.h)+lineHeight
        text = "Le : #{$filter('xinDate')(@date_delivrance, 'shortDate', '+0000')}"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += @_ptTomm(dim.h)+lineHeight
        text = "Valable jusqu'au : #{$filter('xinDate')(@droit.date_fin_validite, 'shortDate', '+0000')}"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += @_ptTomm(dim.h)+lineHeight

        text = "Date de premier enregistrement en guichet unique : #{$filter('xinDate')(@demande_asile.date_enregistrement, 'shortDate', '+0000')}"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += @_ptTomm(dim.h)+lineHeight
        text = "Statut : #{@attestation_label[@droit.sous_type_document]}"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text(20, margin, text)
        margin += @_ptTomm(dim.h)+lineHeight

        if @is_duplicata
          @_pdf.setFontStyle("bold")
          text = "DUPLICATA"
          dim = @_pdf.getTextDimensions(text)
          @_pdf.text((210-dim.w*25.4/72)/2, margin, text)
          margin += @_ptTomm(dim.h)

        # Photo
        # @_pdf.rect(152, 60, 28, 32)
        if @usager.photoPdf?
          @_pdf.addImage(@usager.photoPdf.base64Img, 'PNG', 150, 90, 28, 32)
