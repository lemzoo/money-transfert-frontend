'use strict'


angular.module('xin.pdf.decision_definitive', [])
  .factory 'DecisionDefinitivePdf', ($filter, $q, Backend, SETTINGS, Pdf) ->
    class DecisionDefinitivePdf extends Pdf
      constructor: (@_resourcesList, @_pays, @_user, @_status, @_site) ->
        super
        @_verticalLine_1 = 25
        @_verticalLine_2 = 55
        @_verticalLine_3 = 86
        @_verticalLine_4 = 117
        @_verticalLine_5 = 148
        @_verticalLine_6 = 179
        @_verticalLine_7 = 210
        @_verticalLine_8 = 241
        @_verticalLine_9 = 272
        @_maxWidthText = 29
        @_currentResource = 0
        @_compteur_journalier = "0"

      generate: ->
        defer = $q.defer()
        Backend.one("impression/id").get().then (impressionId) =>
          @_compteur_journalier = ""+impressionId.compteur_journalier
          @_generate()
          defer.resolve()
        return defer.promise

      _generate: ->
        @_pdf = @_newPdf(true)
        @_currentPage = 1
        @_currentResource = 0
        @_setNewPage()

      _finalize: ->
        if not @_resourcesList.length or @_currentResource <= @_resourcesList.length
          @_numberPages()
        else
          @_setNewPage()

      _setNewPage: ->
        @_makeHeaders()
        marginTop = @_tableHeader()
        if not @_resourcesList.length
          marginTop += 10
          @_pdf.setFontType("italic")
          @_pdf.setFontSize(13)
          text = "Pas de résultat"
          width = @_ptTomm(@_pdf.getTextDimensions(text).w)
          @_pdf.text(148-width/2, marginTop, text)
        else
          @_pdf.setFontType("normal")
          first = @_currentResource
          for i in [first..@_resourcesList.length-1] when @_resourcesList.length > 0
            resource = @_resourcesList[i]
            height = @_makeResource(resource)
            currentPage = @_currentPage
            marginTop = @_checkEndPage(marginTop, height, 182, undefined, @_onNewPage).marginTop
            if currentPage == @_currentPage
              marginTop = @_makeResource(resource, @_pdf, marginTop)
              @_currentResource++
            else
              @_setNewPage()
              return
        @_finalize()

      _checkEndPage: (marginTop, height, maxHeight, pageNumber = 0, callbacks = {}) ->
        if pageNumber == 0
          pageNumber = @_currentPage
        numberOfPages = @_pdf.internal.getNumberOfPages()
        if marginTop + height > maxHeight
          if pageNumber >= numberOfPages
            callbacks.onBeforeNewPage?()
            @_pdf.addPage()
            @_currentPage++
            callbacks.onAfterNewPage?()
          else
            @_currentPage = pageNumber+1
            @_pdf.setPage(@_currentPage)
          return {marginTop: 25, pageNumber: @_currentPage}
        return {marginTop: marginTop, pageNumber: pageNumber}


      _makeHeaders: ->
        @_pdf.setFontSize(11)
        @_pdf.setFontType("normal")
        today = moment().format("DD/MM/YYYY HH:mm")
        @_pdf.setDrawColor(80, 80, 80)
        # top
        @_pdf.rect(25, 10, 247, 6)
        status = ""
        if @_status in ["DECISION_DEFINITIVE_ACCORD", "FIN_PROCEDURE_ACCORD"]
          status = "- Accord"
        else if @_status in ["DECISION_DEFINITIVE_REFUS", "FIN_PROCEDURE_REFUS"]
          status = "- Rejet"
        id = "00000"
        id = id.substring(0, 5-@_compteur_journalier.length) + @_compteur_journalier
        id = moment().format("YYYYMMDD") + id
        @_pdf.text(26, 14, "SI asile - Edition des décisions définitives #{status} - #{id}")
        @_pdf.line(170, 10, 170, 16)
        text = "Site : #{@_site}"
        width = @_ptTomm(@_pdf.getTextDimensions(text).w)
        @_pdf.text(@_verticalLine_9-2-width, 14, text)
        # bottom
        @_pdf.rect(25, 192, 247, 6)
        @_pdf.text(26, 196, "Utilisateur : #{@_user}")
        @_pdf.line(107, 192, 107, 198)
        @_pdf.line(189, 192, 189, 198)
        text = "Date d'édition : #{today}"
        width = @_ptTomm(@_pdf.getTextDimensions(text).w)
        @_pdf.text(271-width, 196, text)


      _tableHeader: ->
        maxLineHeight = 1
        @_pdf.setFontType("bold")
        @_pdf.setDrawColor(0, 0, 0)
        # text
        text = "N° de la demande"
        lines = @_pdf.splitTextToSize(text, @_maxWidthText)
        maxLineHeight = Math.max(maxLineHeight, lines.length)
        @_pdf.text(@_verticalLine_1+1, 34, lines)
        text = "Statut de la demande"
        lines = @_pdf.splitTextToSize(text, @_maxWidthText)
        maxLineHeight = Math.max(maxLineHeight, lines.length)
        @_pdf.text(@_verticalLine_2+1, 34, lines)
        text = "N° étranger"
        lines = @_pdf.splitTextToSize(text, @_maxWidthText)
        maxLineHeight = Math.max(maxLineHeight, lines.length)
        @_pdf.text(@_verticalLine_3+1, 34, lines)
        text = "Nom"
        lines = @_pdf.splitTextToSize(text, @_maxWidthText)
        maxLineHeight = Math.max(maxLineHeight, lines.length)
        @_pdf.text(@_verticalLine_4+1, 34, lines)
        text = "Prénom(s)"
        lines = @_pdf.splitTextToSize(text, @_maxWidthText)
        maxLineHeight = Math.max(maxLineHeight, lines.length)
        @_pdf.text(@_verticalLine_5+1, 34, lines)
        text = "Date de naissance"
        lines = @_pdf.splitTextToSize(text, @_maxWidthText)
        maxLineHeight = Math.max(maxLineHeight, lines.length)
        @_pdf.text(@_verticalLine_6+1, 34, lines)
        text = "Nationalité"
        lines = @_pdf.splitTextToSize(text, @_maxWidthText)
        maxLineHeight = Math.max(maxLineHeight, lines.length)
        @_pdf.text(@_verticalLine_7+1, 34, lines)
        text = "Commentaires"
        lines = @_pdf.splitTextToSize(text, @_maxWidthText)
        maxLineHeight = Math.max(maxLineHeight, lines.length)
        @_pdf.text(@_verticalLine_8+1, 34, lines)
        # rect and lines
        rectHeight = 5*maxLineHeight
        @_pdf.rect(@_verticalLine_1, 30, 247, rectHeight)
        @_pdf.line(@_verticalLine_2, 30, @_verticalLine_2, 30+rectHeight)
        @_pdf.line(@_verticalLine_3, 30, @_verticalLine_3, 30+rectHeight)
        @_pdf.line(@_verticalLine_4, 30, @_verticalLine_4, 30+rectHeight)
        @_pdf.line(@_verticalLine_5, 30, @_verticalLine_5, 30+rectHeight)
        @_pdf.line(@_verticalLine_6, 30, @_verticalLine_6, 30+rectHeight)
        @_pdf.line(@_verticalLine_7, 30, @_verticalLine_7, 30+rectHeight)
        @_pdf.line(@_verticalLine_8, 30, @_verticalLine_8, 30+rectHeight)
        return 30+rectHeight


      _numberPages: ->
        @_pdf.setFontSize(11)
        @_pdf.setFontType("normal")
        for i in [1..@_currentPage]
          @_pdf.setPage(i)
          text = "Page #{i} / #{@_currentPage}"
          width = @_ptTomm(@_pdf.getTextDimensions(text).w)
          @_pdf.text((297-width)/2, 196, text)


      _makeResource: (da, pdf = null, marginTop = 0) ->
        pdf = pdf or @_newPdf(true)
        maxLineHeight = 5
        # N° de la demande
        lineHeight = @_addField(da.id, pdf, @_verticalLine_1+1, marginTop)
        maxLineHeight = Math.max(maxLineHeight, lineHeight)
        # Statut de la demande
        lineHeight = @_addField(da.decision_definitive_resultat or "", pdf, @_verticalLine_2+1, marginTop)
        maxLineHeight = Math.max(maxLineHeight, lineHeight)
        # N° étranger
        lineHeight = @_addField(da.usager.identifiant_agdref, pdf, @_verticalLine_3+1, marginTop)
        maxLineHeight = Math.max(maxLineHeight, lineHeight)
        # Nom
        lineHeight = @_addField(da.usager.nom, pdf, @_verticalLine_4+1, marginTop)
        maxLineHeight = Math.max(maxLineHeight, lineHeight)
        # Prénom(s)
        lineHeight = @_addField(da.usager.prenoms, pdf, @_verticalLine_5+1, marginTop)
        maxLineHeight = Math.max(maxLineHeight, lineHeight)
        # Date de naissance
        date = moment(da.usager.date_naissance).format("DD/MM/YYYY")
        lineHeight = @_addField(date, pdf, @_verticalLine_6+1, marginTop)
        maxLineHeight = Math.max(maxLineHeight, lineHeight)
        # Nationalité
        nationalite = da.usager.nationalites[0].libelle
        if not nationalite?
          nationalite = da.usager.nationalites[0].code
        lineHeight = @_addField(nationalite, pdf, @_verticalLine_7+1, marginTop)
        maxLineHeight = Math.max(maxLineHeight, lineHeight)
        # Commentaires
        # lineHeight = @_addField(da.usager.nationalites[0], pdf, @_verticalLine_7+1, marginTop)
        # maxLineHeight = Math.max(maxLineHeight, lineHeight)
        #
        pdf.rect(@_verticalLine_1, marginTop, 247, maxLineHeight)
        pdf.line(@_verticalLine_2, marginTop, @_verticalLine_2, marginTop+maxLineHeight)
        pdf.line(@_verticalLine_3, marginTop, @_verticalLine_3, marginTop+maxLineHeight)
        pdf.line(@_verticalLine_4, marginTop, @_verticalLine_4, marginTop+maxLineHeight)
        pdf.line(@_verticalLine_5, marginTop, @_verticalLine_5, marginTop+maxLineHeight)
        pdf.line(@_verticalLine_6, marginTop, @_verticalLine_6, marginTop+maxLineHeight)
        pdf.line(@_verticalLine_7, marginTop, @_verticalLine_7, marginTop+maxLineHeight)
        pdf.line(@_verticalLine_8, marginTop, @_verticalLine_8, marginTop+maxLineHeight)
        return marginTop+maxLineHeight


      _addField: (text, pdf, marginLeft, marginTop) ->
        lines = pdf.splitTextToSize(text, @_maxWidthText)
        pdf.text(marginLeft, marginTop+4, lines)
        height = 5*lines.length
        return height
