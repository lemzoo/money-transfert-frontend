'use strict'


angular.module('xin.pdf.convocation', [])
  .factory 'ConvocationPdf', ($filter, $q, Pdf, is_minor) ->
    class ConvocationPdf extends Pdf
      constructor: (@usagers, @site, @dateConvocation, @currentSite, @spa) ->
        super
        @_PHOTO_WIDTH = 32
        @_PHOTO_HEIGHT = 33
        @_usagers = []
        @_marianne = {}
        angular.copy(@usagers, @_usagers)

      generate: (language = "") ->
        defer = $q.defer()
        promises = []
        promise = @addPhoto(@_marianne, "images/logo-de-la-republique-francaise.png")
        promises.push(promise)
        for usager in @_usagers
          if usager.photo?
            promise = @addPhoto(usager, @_api_url + usager.photo._links.data)
            promises.push(promise)
          else if usager.photo_premier_accueil?
            promise = @addPhoto(usager, @_api_url + usager.photo_premier_accueil._links.data)
            promises.push(promise)

        $q.all(promises).then(
          () =>
            @_pdf = @_newPdf()
            last_page = @_usagers.length - 1
            for usager, index in @_usagers
              @_makeUsager(usager)
              if index isnt last_page
                @_pdf.addPage()
            defer.resolve()
          (error) ->
            defer.reject(error)
        )
        return defer.promise

      _makeUsager: (usager) ->
        @_pdf.setFont("helvetica")
        @_pdf.setFontSize(11)
        @_pdf.setFontStyle("bold")

        # Site adresse
        lineHeight = 5
        margin = 35
        if @site.libelle?
          @_pdf.text(20, margin, "#{@site.libelle}")
          margin += lineHeight
        if @site.adresse.numero_voie? and @site.adresse.voie?
          @_pdf.text(20, margin, "#{@site.adresse.numero_voie} #{@site.adresse.voie}")
          margin += lineHeight
        else if @site.adresse.numero_voie? and not @site.adresse.voie?
          @_pdf.text(20, margin, "#{@site.adresse.numero_voie}")
          margin += lineHeight
        else if not @site.adresse.numero_voie? and @site.adresse.voie?
          @_pdf.text(20, margin, "#{@site.adresse.voie}")
          margin += lineHeight
        if @site.adresse.code_postal? and @site.adresse.ville?
          @_pdf.text(20, margin, "#{@site.adresse.code_postal} #{@site.adresse.ville}")
          margin += lineHeight
        else if @site.adresse.code_postal? and not @site.adresse.ville?
          @_pdf.text(20, margin, "#{@site.adresse.code_postal}")
          margin += lineHeight
        else if not @site.adresse.code_postal? and @site.adresse.ville?
          @_pdf.text(20, margin, "#{@site.adresse.ville}")
          margin += lineHeight

        # Site phone & mail
        margin += lineHeight
        @_pdf.text(20, margin, "Tél :")
        if @site.telephone?
          @_pdf.text(30, margin, "#{@site.telephone}")
        margin += lineHeight
        @_pdf.text(20, margin, "Mél :")
        if @site.email?
          @_pdf.text(31, margin, "#{@site.email}")

        # Text
        @_pdf.setTextColor(0, 0, 0)
        @_pdf.setFontSize(11)
        text = "CONVOCATION POUR L'ENREGISTREMENT DE LA DEMANDE D'ASILE"
        dim = @_pdf.getTextDimensions(text)
        @_pdf.text((210-dim.w*25.4/72)/2, 80, text)
        @_pdf.setFontStyle("normal")

        # Usager
        margin = 95
        lineHeight = 10
        @_pdf.text(20, margin, "Nom : #{usager.nom}")
        margin += lineHeight
        text = "Prénoms : #{usager.prenoms.toString()}"
        lines = @_pdf.splitTextToSize(text, 120)
        @_pdf.text(20, margin, lines)
        margin += lineHeight+4*(lines.length-1)
        @_pdf.text(20, margin, "Né(e) le : #{$filter('xinDate')(usager.date_naissance, 'shortDate', '+0000')}")
        margin += lineHeight
        lineHeight = 7
        @_pdf.text(20, margin, "A : #{usager.ville_naissance}, #{usager.pays_naissance.libelle}")
        margin += lineHeight

        # Mineur
        if is_minor(usager.date_naissance)
          @_pdf.text(20, margin, "Mineur")
          margin += lineHeight

        # Nationalités
        nationalities = ""
        for nationality, key in usager.nationalites
          if key != 0
            nationalities += ", "
          nationalities += "#{nationality.libelle}"
        @_pdf.text(20, margin, "Nationalité : #{nationalities}")
        margin += lineHeight

        # Adresse
        lineHeight = 5
        @_pdf.text(20, margin, "Adresse :")
        margin += lineHeight
        marginEnd = margin
        text = []
        if usager.adresse.complement?
          text.push("#{usager.adresse.complement}")
          marginEnd += 3.4
        if usager.adresse.numero_voie? or usager.adresse.voie?
          text.push("#{usager.adresse.numero_voie or ''} #{usager.adresse.voie or ''}")
          marginEnd += 3.4
        if usager.adresse.code_postal? or usager.adresse.ville?
          text.push("#{usager.adresse.code_postal or ''} #{usager.adresse.ville or ''}")
          marginEnd += 3.4
        @_pdf.text(30, margin, text)
        margin = marginEnd

        # Chez
        lineHeight = 7
        margin += lineHeight
        if usager.adresse.chez?
          @_pdf.text(20, margin, "Chez : #{usager.adresse.chez}")
        else
          @_pdf.text(20, margin, "Chez :")

        # Enfants
        lineHeight = 10
        margin += lineHeight
        nbrEnfant = usager.enfant_usager_1 or 0
        nbrEnfant14 = usager.enfant_usager_1_14 or 0
        @_pdf.text(20, margin, "Nombre d'enfants présents : #{nbrEnfant}")
        @_pdf.text(90, margin, "dont : #{nbrEnfant14} ayant 14 ans et plus")

        # Date convocation
        margin += lineHeight
        lines = @_pdf.splitTextToSize("est convoqué(e) au guichet unique asile de la Préfecture le #{$filter('xinDate')(@dateConvocation, 'longDate')} à #{$filter('xinDate')(@dateConvocation, 'HH')}h#{$filter('xinDate')(@dateConvocation, 'mm')} pour l'enregistrement de la demande d'asile.", 170)
        @_pdf.text(20, margin, lines)

        # Documents to present
        margin += 10
        @_pdf.text(25, margin, "Documents à présenter :")
        margin += 8
        @_pdf.text(25, margin, "-")
        lines = @_pdf.splitTextToSize("Les indications relatives à son état civil ainsi que, le cas échéant, à celui de son partenaire avec lequel il est lié par une union civile ou de son concubin et à ses enfants à charge ;", 160)
        @_pdf.text(30, margin, lines)
        margin += 10
        @_pdf.text(25, margin, "-")
        lines = @_pdf.splitTextToSize("Les documents justifiant qu’il est entré régulièrement en France ou, à défaut, toutes indications portant sur les conditions de son entrée en France et ses itinéraires de voyage à partir de son pays d’origine ;", 160)
        @_pdf.text(30, margin, lines)
        margin += 15
        @_pdf.text(25, margin, "-")
        lines = @_pdf.splitTextToSize("Quatre photographies de face, tête nue, de format 3,5 cm x 4,5 cm, récentes et parfaitement ressemblantes ;", 160)
        @_pdf.text(30, margin, lines)
        margin += 10
        @_pdf.text(25, margin, "-")
        lines = @_pdf.splitTextToSize("S’il est hébergé par un tiers : une attestation sur l’honneur de l’hébergeant et une photocopie de la pièce d’identité de celui-ci.", 160)
        @_pdf.text(30, margin, lines)

        # titre de séjour
        margin += 15
        lines = @_pdf.splitTextToSize("Si la personne est déjà titulaire d’un titre de séjour délivré par les autorités françaises et en cours de validité, elle fournit uniquement les photographies et les documents justifiant de l’adresse de domiciliation s’il y a lieu.", 170)
        @_pdf.text(20, margin, lines)

        # Signature
        text = "A #{@currentSite.adresse.ville or ""}"
        text += ", le #{$filter('xinDate')(@_today, 'shortDate')}"
        text += " délivrée par :"
        text_spa = @spa.libelle
        dim = @_pdf.getTextDimensions(text)
        dim_spa = @_pdf.getTextDimensions(text_spa)
        width = Math.max(dim.w, dim_spa.w)
        @_pdf.text(190-(width*25.4/72), 275, text)
        @_pdf.text(190-(width*25.4/72), 280, text_spa)

        # Photo
        @_pdf.rect(150, 90, @_PHOTO_WIDTH, @_PHOTO_HEIGHT)
        if usager.photoPdf?
          @_pdf.addImage(usager.photoPdf.base64Img, 'PNG', 150, 90,
                       @_PHOTO_WIDTH, @_PHOTO_HEIGHT)

        # Logo Marianne
        @_pdf.addImage(@_marianne.photoPdf.base64Img, 'PNG', 98, 5, 25, 15)

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
