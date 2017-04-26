'use strict'


angular.module('xin.pdf.planning_jour_gu', [])
  .factory 'PlanningJourGuPdf', ($filter, $q, Pdf,
                                 get_nb_usagers_mobilite_reduite) ->
    class PlanningJourGuPdf extends Pdf
      constructor: (@dateToDisplay, @resourcesList) ->
        super
        @_RECT_HEURE_WIDTH = 40
        @_RESOURCE_HEIGHT = 22
        @_resourcesList = []
        angular.copy(@resourcesList, @_resourcesList)

      generate: (language = "") ->
        defer = $q.defer()
        promises = []
        usagers = []
        for resource in @_resourcesList
          if resource.usager_1? then usagers.push(resource.usager_1)
          if resource.usager_2? then usagers.push(resource.usager_2)
          if resource.enfants then usagers = usagers.concat(resource.enfants)
        for usager in usagers
          if usager.photo?
            promise = @addPhoto(usager, @_api_url + usager.photo._links.data)
            promises.push(promise)
          else if usager.photo_premier_accueil?
            promise = @addPhoto(usager, @_api_url + usager.photo_premier_accueil._links.data)
            promises.push(promise)
        $q.all(promises).then(
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

      _generate: ->
        @_pdf.setFontSize(16)
        @_pdf.setFontType("bold")
        marginTop = 25
        text = $filter("xinDate")(@dateToDisplay, 'shortDate')
        height = @_ptTomm(@_pdf.getTextDimensions(text).h)
        width = @_ptTomm(@_pdf.getTextDimensions(text).w)
        @_pdf.text(105-width/2, marginTop, text)
        marginTop += height
        if not @_resourcesList.length
          @_pdf.setFontType("italic")
          text = "Pas de résultat"
          width = @_ptTomm(@_pdf.getTextDimensions(text).w)
          @_pdf.text(105-width/2, marginTop, text)
        else
          marginTop += 5
          for resource in @_resourcesList
            height = @_makeResource(resource)
            marginTop = @_checkEndPage(marginTop, height, @_pdf).marginTop
            marginTop = @_makeResource(resource, @_pdf, marginTop)

      _makeResource: (resource, pdf = null, marginTop = 0) ->
        photos = []
        if not pdf?
          pdf = @_newPdf()
        marginRect = marginTop-3.8
        # numero recueil
        pdf.setFontType("normal")
        pdf.setFontSize(11)
        text = "Recueil n°#{resource.id}"
        height = @_ptTomm(pdf.getTextDimensions(text).h)
        pdf.text(24+@_RECT_HEURE_WIDTH, marginTop, text)
        marginUsager = marginTop+height
        # usager 1
        marginUsager = @_makeUsager(resource.usager_1, pdf, marginUsager, 24+@_RECT_HEURE_WIDTH)
        # usager 2
        if resource.usager_2? and resource.usager_2.demandeur
          marginUsager = @_makeUsager(resource.usager_2, pdf, marginUsager, 24+@_RECT_HEURE_WIDTH)
          if resource.usager_2.photoPdf
            photos.push(resource.usager_2.photoPdf)

        nombre_mobilite_reduite = get_nb_usagers_mobilite_reduite(resource)

        if nombre_mobilite_reduite > 0
          text = "#{nombre_mobilite_reduite} personne"
          if nombre_mobilite_reduite > 1
            text += "s"
          text += " à mobilité réduite"
          pdf.text(24+@_RECT_HEURE_WIDTH, marginUsager, text)
          marginUsager += 4
        # enfants
        if resource.enfants?
          child_presents_count = 0
          for enfant in resource.enfants or []
            if enfant.demandeur or enfant.present_au_moment_de_la_demande
              child_presents_count++
          text = "#{child_presents_count} enfant"
          if child_presents_count > 1
            text += "s"
          pdf.text(24+@_RECT_HEURE_WIDTH, marginUsager, text)
          marginUsager += 4
#        if resource.fpr?
#          pdf.text(22+@_RECT_HEURE_WIDTH, marginUsager, "FPR")
        if resource.child_14?
          pdf.text(24+@_RECT_HEURE_WIDTH, marginUsager, "Mineur +14ans")
          marginUsager += 4
        if resource.usager_1.photoPdf
          photos.push(resource.usager_1.photoPdf)
        @_usagersPhoto(photos, pdf, marginRect+1)

        marginResourceBottom = Math.max(marginRect+@_RESOURCE_HEIGHT, marginUsager-3)
        # Rect heure convocation
        pdf.setFillColor(245, 245, 245)
        pdf.rect(21, marginRect+1, @_RECT_HEURE_WIDTH, marginResourceBottom-marginRect-2, 'F')
        # heure
        pdf.setFontType("bold")
        pdf.setFontSize(14)
        text = 'Pas de rdv'
        if resource.rendez_vous_gu? and resource.rendez_vous_gu.date?
          text = $filter('xinDate')(resource.rendez_vous_gu.date, 'HH:mm')
        width = @_ptTomm(pdf.getTextDimensions(text).w)
        margin = 21 + @_RECT_HEURE_WIDTH/2 - width/2
        marginHeureTop = marginRect + (marginResourceBottom-marginRect)/2 -4
        pdf.text(margin, marginHeureTop, text)
        # heure convocation
        pdf.setFontType("bolditalic")
        pdf.setFontSize(11)
        text = ''
        if resource.date_convocation?
          text = "Convocation à #{$filter('xinDate')(resource.date_convocation, 'HH:mm')} "
        width = @_ptTomm(pdf.getTextDimensions(text).w)*1.10
        margin = 21 + @_RECT_HEURE_WIDTH/2 - width/2
        marginHeureTop = marginRect + (marginResourceBottom-marginRect)/2 +6
        pdf.text(margin, marginHeureTop, text)
        # big rect
        pdf.rect(20, marginRect, 170, marginResourceBottom-marginRect)
        return marginResourceBottom+6

      _makeUsager: (usager, pdf = null, marginTop = 0, marginLeft = 0) ->
        pdf.setFontType("bold")
        pdf.setFontSize(10)
        text = ""
        if usager.sexe == 'F'
          text += "Mme "
        else if usager.sexe == 'M'
          text += "M. "
        index = 0
        for prenom, index in usager.prenoms
          text += "#{prenom}"
          if index != usager.prenoms.length-1
            text += ', '
        text += " #{usager.nom} "
        if usager.nom_usage?
          text += "#{usager.nom_usage} "
        lines = pdf.splitTextToSize(text, 188-marginLeft)
        pdf.text(marginLeft, marginTop, lines)
        marginTop += lines.length * 4.2
        #
        pdf.setFontType("normal")
        text = "(né"
        if usager.sexe == 'F'
          text += 'e'
        text += " le #{$filter('xinDate')(usager.date_naissance, 'shortDate', '+0000')})"
        text += " - #{usager.nationalites[0].libelle}"
        pdf.text(marginLeft, marginTop, text)
        marginTop += 4
        #
        if usager.langues
          text = "Langues : "
          for langue, index in usager.langues
            text += langue.libelle
            if index != usager.langues.length-1
              text += ", "
          pdf.text(marginLeft, marginTop, text)
          marginTop += 4
        #
        return marginTop

      _usagersPhoto: (photos, pdf = null, marginTop = 0) ->
        marginRight = 186
        maxHeight = 0
        if not pdf?
          pdf = @_newPdf()
        for photo in photos or []
          diff = photo.y/(@_RESOURCE_HEIGHT-2)
          marginRight -= photo.x/diff
          pdf.addImage(photo.base64Img, 'PNG', marginRight, marginTop,
                       photo.x/diff, photo.y/diff)
