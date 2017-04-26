'use strict'


angular.module('xin.pdf.recueil_gu', ['xin.pdf.recueil.traduction'])
  .factory 'RecueilGuPdf', ($filter, $q, Backend, SETTINGS, Pdf, RECUEIL_TRAD, is_minor) ->
    class RecueilGuPdf extends Pdf
      constructor: (@recueil, @usagers, @type_usager_label) ->
        super
        @_topUsager = 0
        @_topSplit = 0
        @_HEIGHT_RECT_FIELD = 4.6
        @_MARGIN_RECT_FIELD = 3.4
        @_PHOTO_WIDTH = 32
        @_PHOTO_HEIGHT = 33
        @_waitingPhotos = []
        @_language = ""
        @_usagers = []
        angular.copy(@usagers, @_usagers)

      getLanguages: ->
        return [
          { id: "ALB", libelle: 'Albanais'},
          { id: "ENG", libelle: 'Anglais'},
          { id: "ARA", libelle: 'Arabe'},
          { id: "ARM", libelle: 'Arménien'},
          { id: "BEN", libelle: 'Bengali'},
          { id: "CHI", libelle: 'Chinois'},
          { id: "HAT", libelle: 'Créole Haïtien'},
          { id: "SPA", libelle: 'Espagnol'},
          { id: "PER", libelle: 'Farsi - Persan'},
          { id: "GEO", libelle: 'Géorgien'},
          { id: "LIN", libelle: 'Lingala'},
          { id: "MON", libelle: 'Mongol'},
          { id: "PUS", libelle: 'Pachto'},
          { id: "URD", libelle: 'Ourdou'},
          { id: "POR", libelle: 'Portugais'},
          { id: "RUM", libelle: 'Roumain'},
          { id: "RUS", libelle: 'Russe'},
          { id: "SRP", libelle: 'Serbe'},
          { id: "SWA", libelle: 'Swahili'},
          { id: "TAM", libelle: 'Tamoul'},
          { id: "CHE", libelle: 'Tchétchène'},
          { id: "TIR", libelle: 'Tigrigna'},
          { id: "TUR", libelle: 'Turc'},
          { id: "VIE", libelle: 'Viétnamien'}
        ]

      generate: (language = "") ->
        defer = $q.defer()
        usagers_promises = []
        for res in @_usagers
          if res.usager.photo?
            promise = @addPhoto(res.usager, @_api_url+res.usager.photo._links.data)
            usagers_promises.push(promise)
          else if res.usager.photo_premier_accueil?
            promise = @addPhoto(res.usager, @_api_url+res.usager.photo_premier_accueil._links.data)
            usagers_promises.push(promise)
        $q.all(usagers_promises).then(
          () =>
            @_pdf = @_newPdf()
            @_currentPage = 1
            @_language = language
            totalHeight = @_recueilHeader(@_pdf, 25)
            for usager in @_usagers
              totalHeight = @_makeUsager(usager, totalHeight)
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

      _recueilHeader: (pdf = null, marginTop = 0) ->
        if not pdf?
          pdf = @_newPdf()
        pdf.setFontSize(15)
        # Recueil title
        text = "Recueil n° #{@recueil.id}"
        height = @_ptTomm(pdf.getTextDimensions(text).h)
        pdf.text(20, marginTop, text)
        marginTop += height
        if @_language != ""
          text = "(#{RECUEIL_TRAD[@_language].RECUEIL_N})"
          marginTop = @_addTraduction(text, pdf, marginTop, 20)
        return marginTop

      _headerPaRealise: (pdf = null, marginTop = 0) ->
        if not pdf?
          pdf = @_newPdf()
        pdf.setFontSize(15)
        text = "Identification des demandeurs d'asile"
        height = @_ptTomm(pdf.getTextDimensions(text).h)
        pdf.text(20, marginTop, text)
        marginTop += height
        pdf.setFontType('italic')
        pdf.setFontSize(10)
        text = "La validation des identités des demandeurs est définitive, cela permet de leur attribuer un n° étranger"
        height = @_ptTomm(pdf.getTextDimensions(text).h)
        pdf.text(20, marginTop, text)
        marginTop += height
        return marginTop

      _headerDemandeursIdentifies: (pdf = null, marginTop = 0) ->
        if not pdf?
          pdf = @_newPdf()
        pdf.setFontSize(15)
        text = "Enregistrement des procédures et validations des identités des non demandeurs."
        height = @_ptTomm(pdf.getTextDimensions(text).h)
        pdf.text(20, marginTop, text)
        marginTop += height
        pdf.setFontType('italic')
        pdf.setFontSize(10)
        text = "Cette étape va terminer l'enregistrement du recueil et créer les demandes d'asile correspondantes"
        height = @_ptTomm(pdf.getTextDimensions(text).h)
        pdf.text(20, marginTop, text)
        marginTop += height
        return marginTop

      _makeUsager: (usager, marginTop) ->
        typeUsager = usager.type_usager
        usager = usager.usager
        # header
        height = @_usagerHeader(usager, typeUsager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf).marginTop
        @_beginBigScopeRect(marginTop)
        marginTop = @_usagerHeader(usager, typeUsager, @_pdf, marginTop)
        # nom
        height = @_usagerNom(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerNom(usager, @_pdf, marginTop)
        # origine nom
        height = @_usagerOrigineNom(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerOrigineNom(usager, @_pdf, marginTop)
        # nom usage
        height = @_usagerNomUsage(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerNomUsage(usager, @_pdf, marginTop)
        # origine nom usage
        height = @_usagerOrigineNomUsage(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerOrigineNomUsage(usager, @_pdf, marginTop)
        # prenoms
        height = @_usagerPrenoms(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerPrenoms(usager, @_pdf, marginTop)
        # Numéro étranger
        if usager.identifiant_agdref?
          height = @_usagerIdentifiantAgdref(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerIdentifiantAgdref(usager, @_pdf, marginTop)
        # sexe
        height = @_usagerSexe(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerSexe(usager, @_pdf, marginTop)
        # date de naissance
        height = @_usagerDateNaissance(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerDateNaissance(usager, @_pdf, marginTop)
        # informations pour mineurs demandeurs
        if usager.demandeur and is_minor(usager.date_naissance)
          # profil de demande
          height = @_usagerProfilDemande(usager, typeUsager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerProfilDemande(usager, typeUsager, @_pdf, marginTop)
          # nom représentant légal
          height = @_usagerNomRepresentantLegal(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerNomRepresentantLegal(usager, @_pdf, marginTop)
          # prénom représentant légal
          height = @_usagerPrenomRepresentantLegal(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerPrenomRepresentantLegal(usager, @_pdf, marginTop)
          # représentant légal personne morale
          height = @_usagerRepresentantPersonneMorale(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerRepresentantPersonneMorale(usager, @_pdf, marginTop)
          # désignation de la personne morale
          if usager.representant_legal_personne_morale
            height = @_usagerDesignationPersonneMorale(usager)
            marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
            marginTop = @_usagerDesignationPersonneMorale(usager, @_pdf, marginTop)
        # nationalite
        height = @_usagerNationalite(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerNationalite(usager, @_pdf, marginTop)
        # Photo
        if usager.demandeur
          height = @_usagerPhoto(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerPhoto(usager, @_pdf, marginTop)
        # date d'arrivée en France
        if usager.demandeur
          height = @_usagerDateArriveeFrance(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerDateArriveeFrance(usager, @_pdf, marginTop)
        # date de depart
        if usager.demandeur
          height = @_usagerDateDepart(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerDateDepart(usager, @_pdf, marginTop)
        # pays traversés
        if usager.demandeur
          height = @_usagerPaysTraverses(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerPaysTraverses(usager, @_pdf, marginTop)
        # usager présent
        if not usager.demandeur
          height = @_usagerPresent(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerPresent(usager, @_pdf, marginTop)
        # ville de naissance
        height = @_usagerVilleNaissance(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerVilleNaissance(usager, @_pdf, marginTop)
        # pays naissance
        height = @_usagerPaysNaissance(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerPaysNaissance(usager, @_pdf, marginTop)
        # situation familiale
        if typeUsager != 'usager2'
          height = @_usagerSituationFamiliale(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerSituationFamiliale(usager, @_pdf, marginTop)
        # langues
        if usager.demandeur
          height = @_usagerLangues_iso639_2(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerLangues_iso639_2(usager, @_pdf, marginTop)
        # langues OFPRA
        if usager.demandeur
          height = @_usagerLangues_OFPRA(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerLangues_OFPRA(usager, @_pdf, marginTop)
        # nom père
        height = @_usagerNomPere(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerNomPere(usager, @_pdf, marginTop)
        # prenom père
        height = @_usagerPrenomPere(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerPrenomPere(usager, @_pdf, marginTop)
        # nom mère
        height = @_usagerNomMere(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerNomMere(usager, @_pdf, marginTop)
        # prenom mère
        height = @_usagerPrenomMere(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerPrenomMere(usager, @_pdf, marginTop)
        # enfant usager 1 & 2
        if typeUsager == 'enfant'
          height = @_usagerEnfantUsager1(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerEnfantUsager1(usager, @_pdf, marginTop)
          height = @_usagerEnfantUsager2(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerEnfantUsager2(usager, @_pdf, marginTop)
        # telephone
        height = @_usagerTelephone(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerTelephone(usager, @_pdf, marginTop)
        # email
        height = @_usagerEmail(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerEmail(usager, @_pdf, marginTop)
        # adresse
        height = @_usagerAdresse()
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerAdresse(@_pdf, marginTop)
        # adresse inconnue
        height = @_usagerAdresseInconnue(usager)
        marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
        marginTop = @_usagerAdresseInconnue(usager, @_pdf, marginTop)
        # adresse complète
        if not usager.adresse.adresse_inconnue
          # chez
          height = @_usagerAdresseChez(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerAdresseChez(usager, @_pdf, marginTop)
          # complement
          height = @_usagerAdresseComplement(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerAdresseComplement(usager, @_pdf, marginTop)
          # numéro de voie
          height = @_usagerAdresseNumVoie(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerAdresseNumVoie(usager, @_pdf, marginTop)
          # voie
          height = @_usagerAdresseVoie(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerAdresseVoie(usager, @_pdf, marginTop)
          # ville
          height = @_usagerAdresseVille(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerAdresseVille(usager, @_pdf, marginTop)
          # code insee
          height = @_usagerAdresseCodeInsee(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerAdresseCodeInsee(usager, @_pdf, marginTop)
          # code postal
          height = @_usagerAdresseCodePostal(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerAdresseCodePostal(usager, @_pdf, marginTop)
          # pays
          height = @_usagerAdressePays(usager)
          marginTop = @_checkEndPage(marginTop, height, @_pdf, 0, @_newLineCallbacks()).marginTop
          marginTop = @_usagerAdressePays(usager, @_pdf, marginTop)
        marginTop += 5
        @_stopBigScopeRect(marginTop)
        marginTop += 1
        return marginTop

      _usagerHeader: (usager, typeUsager, pdf = null, marginTop = 0) ->
        if not pdf?
          pdf = @_newPdf()
        marginOrig = marginTop-4
        pdf.setDrawColor(0, 0, 0)
        # Type + name
        @_configUsagerTitle(pdf)
        text = "#{@type_usager_label[typeUsager]} - "
        dim = pdf.getTextDimensions(text)
        height = @_ptTomm(dim.h)
        width = @_ptTomm(dim.w)
        pdf.text(22, marginTop, text)
        pdf.setFontType("bold")
        prenoms = ""
        for prenom in usager.prenoms
          prenoms += "#{prenom} "
        pdf.text(22+width, marginTop, "#{prenoms}#{usager.nom}")
        # demandeur oui/non
        @_configNormal(pdf)
        text = "Non"
        if usager.demandeur
          text = "Oui"
        widthYesNo = @_ptTomm(pdf.getTextDimensions(text).w)
#        pdf.rect(184-widthYesNo, marginTop-@_MARGIN_RECT_FIELD, widthYesNo+4, @_HEIGHT_RECT_FIELD)
        pdf.text(186-widthYesNo, marginTop, text)
        # demandeur
        @_configFieldTitle(pdf)
        text = "Demandeur"
        width = @_ptTomm(pdf.getTextDimensions(text).w)
        pdf.text(183-widthYesNo-width, marginTop, text)
        marginTop += height
        # if @_language != ""
        #   text = "(#{RECUEIL_TRAD[@_language].TYPE_USAGER[typeUsager]})"
        #   @_addTraduction(text, pdf, marginTop, 22)
        #   text = "(#{RECUEIL_TRAD[@_language].DEMANDEUR})"
        #   marginTop = @_addTraduction(text, pdf, marginTop, 183-widthYesNo-width)
        # rect
        diff = marginTop-marginOrig-2
        pdf.rect(20, marginOrig, 170, diff)
        marginTop += 3
        return marginTop

      _usagerIdentityTitle: (pdf = null, marginTop = 0) ->
        if not pdf?
          pdf = @_newPdf()
        @_configUsagerPartTitle(pdf)
        text = "Identité"
        height = @_ptTomm(pdf.getTextDimensions(text).h)
        pdf.text(22, marginTop, text)
        marginTop += height
        if @_language != ""
          text = "(#{RECUEIL_TRAD[@_language].INDICATIONS_ETAT_CIVIL_DEMANDEUR})"
          marginTop = @_addTraduction(text, pdf, marginTop, 22)
        pdf.setDrawColor(194, 194, 194)
        marginLine = marginTop-1.5
        pdf.line(22, marginLine, 188, marginLine)
        marginTop += 2.5
        return marginTop

      _usagerNom: (usager, pdf = null, marginTop = 0) ->
        title = "Nom *"
        value = [usager.nom]
        trad = 'NOM'
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerOrigineNom: (usager, pdf = null, marginTop = 0) ->
        title = "Origine du nom *"
        value = [usager.origine_nom]
        trad = null
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerNomUsage: (usager, pdf = null, marginTop = 0) ->
        title = "Nom d'usage"
        value = [usager.nom_usage or '']
        trad = 'NOM_USAGE'
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerOrigineNomUsage: (usager, pdf = null, marginTop = 0) ->
        title = "Origine du nom d'usage"
        value = [usager.origine_nom_usage or '']
        trad = null
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerPrenoms: (usager, pdf = null, marginTop = 0) ->
        title = "Prénom(s) *"
        value = usager.prenoms
        trad = 'PRENOMS'
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerIdentifiantAgdref: (usager, pdf = null, marginTop = 0) ->
        title = "N° étranger"
        value = [usager.identifiant_agdref]
        trad = 'NUMERO_ETRANGER'
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerPresent: (usager, pdf = null, marginTop = 0) ->
        title = "Présent au moment de la demande"
        value = ["Non"]
        if usager.present_au_moment_de_la_demande
          value = ["Oui"]
        if usager.present_au_moment_de_la_demande == undefined
          value = ["Non précisé"]
#        trad = 'PRESENT'
        return @_addField(title, value, null, 22, marginTop, 80, pdf)

      _usagerSexe: (usager, pdf = null, marginTop = 0) ->
        title = "Sexe *"
        value = [usager.sexe]
        trad = "M"
        if usager.sexe == "F"
          trad = "F"
        trad = null
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerPhoto: (usager, pdf = null, marginTop = 0) ->
        if not pdf?
          pdf = @_newPdf()
        @_configFieldTitle(pdf)
        text = "Photo *"
        height = @_ptTomm(pdf.getTextDimensions(text).h)
        pdf.text(22, marginTop, text)
        marginTop += height
        # if @_language != ""
        #   text = "(#{RECUEIL_TRAD[@_language].PHOTO})"
        #   marginTop = @_addTraduction(text, pdf, marginTop, 107)
        marginPhoto = marginTop+3
        pdf.rect(22, marginPhoto, @_PHOTO_WIDTH, @_PHOTO_HEIGHT)
        if usager.photoPdf?
          pdf.addImage(usager.photoPdf.base64Img, 'PNG', 22, marginPhoto,
                       usager.photoPdf.x, usager.photoPdf.y)
        return marginPhoto+@_PHOTO_HEIGHT+5

      _usagerDateNaissance: (usager, pdf = null, marginTop = 0) ->
        title = "Date de naissance *"
        value = $filter('date')(usager.date_naissance, 'shortDate', '+0000')
        if usager.date_naissance_approximative?
          value += " Approximative"
        trad = 'DATE_NAISSANCE'
        marginTop = @_addField(title, [value], trad, 22, marginTop, 80, pdf)
        return marginTop

      _usagerProfilDemande: (usager, typeUsager, pdf = null, marginTop = 0) ->
        title = "Profil de demande *"
        value = ['']
        if typeUsager == 'usager1'
          value = ["Mineur isolé"]
        else
          value = ["Mineur accompagnant"]
#        trad = 'PROFIL_DEMANDE_MINEUR'
        return @_addField(title, value, null, 26, marginTop, 76, pdf)

      _usagerNomRepresentantLegal: (usager, pdf = null, marginTop = 0) ->
        title = "Nom du représentant légal"
        value = [usager.representant_legal_nom or '']
#        trad = 'NOM_REPRESENTANT_LEGAL'
        return @_addField(title, value, null, 26, marginTop, 76, pdf)

      _usagerPrenomRepresentantLegal: (usager, pdf = null, marginTop = 0) ->
        title = "Prénom du représentant légal"
        value = [usager.representant_legal_prenom or '']
#        trad = 'PRENOM_REPRESENTANT_LEGAL'
        return @_addField(title, value, null, 26, marginTop, 76, pdf)

      _usagerRepresentantPersonneMorale: (usager, pdf = null, marginTop = 0) ->
        title = "Représentant légal, personne morale ?"
        value = ["Non"]
        if usager.representant_legal_personne_morale
          value = ["Oui"]
#        trad = 'PERSONNE_MORALE'
        return @_addField(title, value, null, 26, marginTop, 76, pdf)

      _usagerDesignationPersonneMorale: (usager, pdf = null, marginTop = 0) ->
        title = "Désignation de la personne morale"
        value = [usager.representant_legal_personne_morale_designation or '']
#        trad = 'DESIGNATION_PERSONNE_MORALE'
        return @_addField(title, value, null, 26, marginTop, 76, pdf)

      _usagerVilleNaissance: (usager, pdf = null, marginTop = 0) ->
        title = "Ville de naissance *"
        value = [usager.ville_naissance or '']
        trad = 'LIEU_NAISSANCE'
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerPaysNaissance: (usager, pdf = null, marginTop = 0) ->
        title = "Pays de naissance *"
        value = [usager.pays_naissance.libelle or '']
        trad = 'LIEU_NAISSANCE'
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerNationalite: (usager, pdf = null, marginTop = 0) ->
        title = "Nationalité *"
        value = [usager.nationalites[0].libelle or '']
        trad = 'NATIONALITE'
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerNomPere: (usager, pdf = null, marginTop = 0) ->
        title = "Nom du père"
        value = [usager.nom_pere or '']
        trad = 'NOM_PRENOM_PERE'
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerPrenomPere: (usager, pdf = null, marginTop = 0) ->
        title = "Prénom du père"
        value = [usager.prenom_pere or '']
        trad = 'NOM_PRENOM_PERE'
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerNomMere: (usager, pdf = null, marginTop = 0) ->
        title = "Nom de la mère"
        value = [usager.nom_mere or '']
        trad = 'NOM_PRENOM_MERE'
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerPrenomMere: (usager, pdf = null, marginTop = 0) ->
        title = "Prénom de la mère"
        value = [usager.prenom_mere or '']
        trad = 'NOM_PRENOM_MERE'
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerDateArriveeFrance: (usager, pdf = null, marginTop = 0) ->
        title = "Date d'arrivée en France *"
        value = ''
        if usager.date_entree_en_france?
          value = $filter('date')(usager.date_entree_en_france, 'shortDate', '+0000')
          if usager.date_entree_en_france_approximative?
            value += " Approximative"
        trad = 'DATE_ENTREE'
        return @_addField(title, [value], trad, 22, marginTop, 80, pdf)

      _usagerDateDepart: (usager, pdf = null, marginTop = 0) ->
        title = "Date de départ du pays d'origine *"
        value = ''
        if usager.date_depart?
          value = $filter('date')(usager.date_depart, 'shortDate', '+0000')
          if usager.date_depart_approximative?
            value += " Approximative"
        trad = 'DATE_DEPART_PAYS_ORIGINE'
        return @_addField(title, [value], trad, 22, marginTop, 80, pdf)

      _usagerPaysTraverses: (usager, pdf = null, marginTop = 0) ->
        if not usager.pays_traverses? or usager.pays_traverses.length == 0
          title = "Pays traversés"
          value = ["Aucun pays traversé"]
          trad = 'PAYS_TRAVERSES'
          return @_addField(title, value, trad, 22, marginTop, 80, pdf)
        else
          if not pdf?
            pdf = @_newPdf()
          marginLeft = 22
          width = 80
          # Titre
          @_configFieldTitle(pdf)
          text = "Pays traversés"
          height = @_ptTomm(pdf.getTextDimensions(text).h)
          pdf.text(marginLeft, marginTop, text)
          marginTop += height
          # Traduction
          if @_language != ""
            text = "(#{RECUEIL_TRAD[@_language]['PAYS_TRAVERSES']})"
            marginTop = @_addTraduction(text, pdf, marginTop, marginLeft)
          pdf.setDrawColor(0, 0, 0)
          for value in usager.pays_traverses or []
            marginPays = marginTop
            # nom pays
            @_configFieldTitle(pdf)
            text = "#{value.pays.libelle} "
            pdf.text(marginLeft+1, marginTop, text)
            height = @_ptTomm(pdf.getTextDimensions(text).h)
            marginTop += height
            # dates
            @_configNormal(pdf)
            text = "(#{$filter('xinDate')(value.date_entree, 'shortDate', '+0000') or ''}#{if value.date_entree_approximative then '~' else ''}"
            text += " - "
            text += "#{$filter('xinDate')(value.date_sortie, 'shortDate', '+0000') or ''}#{if value.date_sortie_approximative then '~' else ''})"
            pdf.text(marginLeft+1, marginTop, text)
            height = @_ptTomm(pdf.getTextDimensions(text).h)
            marginTop += height
            # Traduction dates
            if @_language != ""
              text = "(#{RECUEIL_TRAD[@_language]['DATE_ENTREE']} - #{RECUEIL_TRAD[@_language]['DATE_SORTIE']})"
              marginTop = @_addTraduction(text, pdf, marginTop, marginLeft+1)
            # moyen transport
            text = "Moyen de transport : #{value.moyen_transport or ''}"
            lines = pdf.splitTextToSize(text, 78)
            pdf.text(marginLeft+1, marginTop, lines)
            height = @_ptTomm(pdf.getTextDimensions(lines).h)*lines.length
            marginTop += height
            # traduction moyen transport
            if @_language != ""
              text = "(#{RECUEIL_TRAD[@_language]['MOYENS_TRANSPORTS']})"
              marginTop = @_addTraduction(text, pdf, marginTop, marginLeft+1)
            # condition
            text = "Condition de franchissement : #{value.condition_franchissement or ''}"
            lines = pdf.splitTextToSize(text, 78)
            pdf.text(marginLeft+1, marginTop, lines)
            height = @_ptTomm(pdf.getTextDimensions(lines).h)*lines.length
            marginTop += height
            # traduction condition
            if @_language != ""
              text = "(#{RECUEIL_TRAD[@_language]['CONDITIONS_FRANCHISSEMENT_FRONTIERES']})"
              marginTop = @_addTraduction(text, pdf, marginTop, marginLeft+1)
            height = marginTop - marginPays
            pdf.rect(marginLeft, marginPays-@_MARGIN_RECT_FIELD, width, height)
            marginTop += 0.5
          marginTop += 2
          return marginTop

      _usagerSituationFamiliale: (usager, pdf = null, marginTop = 0) ->
        title = "Situation familiale *"
        value = ''
        trad = null
        switch usager.situation_familiale
          when "" then value = ''
          when "CELIBATAIRE" then value = "Célibataire"; trad = 'CELIBATAIRE'
          when "DIVORCE" then value = "Divorcé(e)"; trad = 'DIVORCE'
          when "MARIE" then value = "Marié(e)"; trad = 'MARIE'
          when "CONCUBIN" then value = "Concubin(e)"; trad = 'CONCUBIN'
          when "SEPARE" then value = "Séparé(e)"
          when "VEUF" then value = "Veuf(ve)"; trad = 'VEUF'
          when "PACSE" then value = "Pacsé(e)"
        trad = null
        return @_addField(title, [value], trad, 22, marginTop, 80, pdf)

      _usagerLangues_iso639_2: (usager, pdf = null, marginTop = 0) ->
        title = "Langue(s) comprise(s) *"
        value = []
        for language in usager.langues
          value.push(language.libelle)
        trad = 'LANGUES'
        return @_addField(title, value, trad, 22, marginTop, 80, pdf)

      _usagerLangues_OFPRA: (usager, pdf = null, marginTop = 0) ->
        title = "Langue d'audition à l'OFPRA *"
        value = [usager.langues_audition_OFPRA[0].libelle or '']
#        trad = 'LANGUE_OFPRA'
        return @_addField(title, value, null, 22, marginTop, 80, pdf)

      _usagerTelephone: (usager, pdf = null, marginTop = 0) ->
        title = "Téléphone"
        value = [usager.telephone or '']
#        trad = 'TELEPHONE'
        return @_addField(title, value, null, 22, marginTop, 80, pdf)

      _usagerEmail: (usager, pdf = null, marginTop = 0) ->
        title = "Email"
        value = [usager.email or '']
#        trad = 'EMAIL'
        return @_addField(title, value, null, 22, marginTop, 80, pdf)

      _usagerEnfantUsager1: (usager, pdf = null, marginTop = 0) ->
        title = "Enfant de l'usager 1"
        value = ["Non"]
        if usager.usager_1
          value = ["Oui"]
#        trad = 'ENFANT_USAGER_1'
        return @_addField(title, value, null, 22, marginTop, 80, pdf)

      _usagerEnfantUsager2: (usager, pdf = null, marginTop = 0) ->
        title = "Enfant de l'usager 2"
        value = ["Non"]
        if usager.usager_2
          value = ["Oui"]
#        trad = 'ENFANT_USAGER_2'
        return @_addField(title, value, null, 22, marginTop, 80, pdf)

      _usagerAdresse: (pdf = null, marginTop = 0) ->
        if not pdf?
          pdf = @_newPdf()
        pdf.setDrawColor(194, 194, 194)
        marginLine = marginTop
        pdf.line(24, marginLine, 186, marginLine)
        marginTop += 6
        @_configUsagerPartTitle(pdf)
        text = "Adresse *"
        height = @_ptTomm(pdf.getTextDimensions(text).h)
        pdf.text(24, marginTop, text)
        marginTop += height
        if @_language != ""
          text = "(#{RECUEIL_TRAD[@_language].ADRESSE_COURRIER})"
          marginTop = @_addTraduction(text, pdf, marginTop, 24)
        marginTop += 0
        return marginTop

      _usagerAdresseInconnue: (usager, pdf = null, marginTop = 0) ->
        title = "Adresse inconnue"
        value = ["Non"]
        if usager.adresse.adresse_inconnue
          value = ["Oui"]
#        trad = 'ADRESSE_INCONNUE'
        return @_addField(title, value, null, 24, marginTop, 78, pdf)

      _usagerAdresseChez: (usager, pdf = null, marginTop = 0) ->
        title = "Chez"
        value = [usager.adresse.chez or '']
        trad = 'CHEZ'
        return @_addField(title, value, trad, 24, marginTop, 162, pdf)

      _usagerAdresseComplement: (usager, pdf = null, marginTop = 0) ->
        title = "Complément"
        value = [usager.adresse.complement or '']
#        trad = 'COMPLEMENT'
        return @_addField(title, value, null, 24, marginTop, 162, pdf)

      _usagerAdresseNumVoie: (usager, pdf = null, marginTop = 0) ->
        title = "Numéro de voie"
        value = [usager.adresse.numero_voie or '']
        trad = 'NUMERO_VOIE'
        return @_addField(title, value, trad, 24, marginTop, 162, pdf)

      _usagerAdresseVoie: (usager, pdf = null, marginTop = 0) ->
        title = "Voie"
        value = [usager.adresse.voie or '']
        trad = 'VOIE'
        return @_addField(title, value, trad, 24, marginTop, 162, pdf)

      _usagerAdresseVille: (usager, pdf = null, marginTop = 0) ->
        title = "Ville"
        value = [usager.adresse.ville or '']
        trad = 'VILLE'
        return @_addField(title, value, trad, 24, marginTop, 162, pdf)

      _usagerAdresseCodeInsee: (usager, pdf = null, marginTop = 0) ->
        title = "Code Insee"
        value = [usager.adresse.code_insee or '']
#        trad = 'CODE_INSEE'
        return @_addField(title, value, null, 24, marginTop, 162, pdf)

      _usagerAdresseCodePostal: (usager, pdf = null, marginTop = 0) ->
        title = "Code Postal"
        value = [usager.adresse.code_postal or '']
        trad = 'CODE_POSTAL'
        return @_addField(title, value, trad, 24, marginTop, 162, pdf)

      _usagerAdressePays: (usager, pdf = null, marginTop = 0) ->
        title = "Pays"
        value = ['']
        if usager.adresse.pays? and usager.adresse.pays.libelle?
          value = [usager.adresse.pays.libelle]
#        trad = 'PAYS'
        return @_addField(title, value, null, 24, marginTop, 162, pdf)

      _addField: (title, values, trad, marginLeft, marginTop, width, pdf = null) ->
        if not pdf?
          pdf = @_newPdf()
        # Title
        @_configFieldTitle(pdf)
        text = title
        height = @_ptTomm(pdf.getTextDimensions(text).h)
        pdf.text(marginLeft, marginTop, text)
        marginTop += height
        # Sub title
        if @_language != "" and trad != null
          text = "(#{RECUEIL_TRAD[@_language][trad]})"
          marginTop = @_addTraduction(text, pdf, marginTop, marginLeft)
        pdf.setDrawColor(0, 0, 0)
        @_configNormal(pdf)
        for value in values
          pdf.rect(marginLeft, marginTop-@_MARGIN_RECT_FIELD, width, @_HEIGHT_RECT_FIELD)
          if value?
            pdf.text(marginLeft+2, marginTop, value)
          marginTop += 5.5
        marginTop += 1
        return marginTop

      _beginBigScopeRect: (marginTop) ->
        @_topUsager = marginTop

      _stopBigScopeRect: (marginTop) ->
        marginTop -= 6
        @_pdf.setDrawColor(0, 0, 0)
        @_pdf.line(20, @_topUsager, 20, marginTop)
        @_pdf.line(190, @_topUsager, 190, marginTop)
        @_pdf.line(20, marginTop, 190, marginTop)

      _pauseBigScopeRect: (marginTop) =>
        @_pdf.setDrawColor(0, 0, 0)
        @_pdf.line(20, @_topUsager, 20, marginTop)
        @_pdf.line(190, @_topUsager, 190, marginTop)

      _newLineCallbacks: ->
        onBeforeNewPage: =>
          marginTop = 272
          @_pauseBigScopeRect(marginTop)
        onAfterNewPage: =>
          marginTop = 25
          @_beginBigScopeRect(marginTop)
