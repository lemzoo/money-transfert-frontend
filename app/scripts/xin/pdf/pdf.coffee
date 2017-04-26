'use strict'


angular.module('xin.pdf', ['xin.pdf.convocation', 'xin.pdf.attestation',
                           'xin.pdf.recueil_pa', 'xin.pdf.recueil_gu',
                           'xin.pdf.planning_jour_gu'
                           'xin.pdf.decision_definitive'
                           'xin.pdf.remise_titres', 'xin.pdf.demande_asile'])
  .factory 'pdfFactory', (ConvocationPdf, AttestationPdf, RecueilGuPdf, RecueilPaPdf,
                          PlanningJourGuPdf, DecisionDefinitivePdf, RemiseTitresPdf,
                          DemandeAsilePdf) ->
    (docType, params, callback = null) ->
      if docType == 'convocation'
        return new ConvocationPdf(params.usagers, params.site, params.dateConvocation,
                                  params.currentSite, params.spa)
      else if docType == 'attestation'
        return new AttestationPdf(params.usager, params.isMinor, params.demande_asile,
                                  params.lieu_delivrance,
                                  params.date_delivrance, params.droit,
                                  params.attestation_label, params.is_duplicata)
      else if docType == 'recueil_pa'
        return new RecueilPaPdf(params.recueil_da, params.usagers, params.type_usager_label)
      else if docType == 'recueil_gu'
        return new RecueilGuPdf(params.recueil_da, params.usagers, params.type_usager_label)
      else if docType == 'planning_jour_gu'
        return new PlanningJourGuPdf(params.dateToDisplay, params.resourcesList)
      else if docType == 'decision_definitive'
        return new DecisionDefinitivePdf(params.resourcesList, params.pays, params.user,
                                         params.status, params.site)
      else if docType == 'remise_titres'
        return new RemiseTitresPdf(params.usager, params.timbre)
      else if docType == 'demande_asile'
        return new DemandeAsilePdf(params.demande_asile, params.usager, params.droits,
                                   params.lieux_delivrances, params.requalifications,
                                   params.localisations, params.portail)
      return null


  .factory 'Pdf', ($filter, $q, Backend, SETTINGS) ->
    class Pdf
      constructor: ->
        @_usagers = []
        @_today = new Date()
        @_pdf = null
        @_currentPage = 1
        @_toStart = false
        @_ready = false
        @_api_url = SETTINGS.API_BASE_URL

      _newPdf: (landscape = false) ->
        pdf = null
        if landscape
          pdf = new jsPDF('landscape')
        else
          pdf = new jsPDF()
        pdf.setFont('helvetica')
        return pdf

      save: (filename) ->
        @_pdf.save(filename)

      _convertImgToBase64URL: (url) ->
        defer = $q.defer()
        img = new Image()
        img.crossOrigin="anonymous"
        img.onload = ->
          canvas = document.createElement('canvas')
          ctx = canvas.getContext('2d')
          canvas.height = this.height
          canvas.width = this.width
          ctx.drawImage(this, 0, 0)
          dataURL = canvas.toDataURL()
          result =
            dataURL: dataURL
            width: this.width
            height: this.height
          defer.resolve(result)
          canvas = null
        img.onerror = (e) ->
          defer.reject(e)
        img.src = url
        return defer.promise

      _addPhoto: (target, base64Img, width, height) =>
        ratio = 31/32
        ratioImg = width/height
        if ratioImg > ratio
          x = 31
          y = 31/ratioImg
        else
          x = 32*ratioImg
          y = 32
        target['photoPdf'] = {base64Img: base64Img, x: x, y: y}

      _configNormal: (pdf) ->
        pdf.setFontSize(11)
        pdf.setFontType("normal")

      _configFieldTitle: (pdf) ->
        pdf.setFontSize(10)
        pdf.setFontType("bold")

      _configUsagerTitle: (pdf) ->
        pdf.setFontSize(11)
        pdf.setFontType("normal")

      _configUsagerPartTitle: (pdf) ->
        pdf.setFontSize(12)
        pdf.setFontType("normal")

      _ptTomm: (a) ->
        return a*26/72

      _mmToPx: (a) ->
        return a*72/25.4

      _addTraduction: (text = "", pdf = null, marginTop = 0, marginLeft = 0, maxWidth = 78) ->
        if not pdf?
          pdf = @_newPdf()
        maxWidth = @_mmToPx(maxWidth)
        marginTop -= 4
        canvas = document.createElement("canvas")
        ctx = canvas.getContext('2d')
        ctx.font = "italic 12px Times New Roman"
        # split text and calcul width
        words = text.split(" ")
        line = ""
        linesCount = 1
        for n in [0..words.length-1]
          testLine = line += words[n]
          testWidth = ctx.measureText(testLine).width
          if testWidth > maxWidth
            ctx.fillText(line, 0, 12*linesCount)
            line = words[n] + " "
            linesCount++
          else
            line = testLine + " "
        ctx.fillText(line, 0, 12*linesCount)
        imgData = canvas.toDataURL()
        pdf.addImage(imgData, 'PNG', marginLeft, marginTop)
        marginTop += 4*linesCount+4
        return marginTop

      _checkEndPage: (marginTop, height, pdf, pageNumber = 0, callbacks = {}) ->
        if pageNumber == 0
          pageNumber = @_currentPage
        numberOfPages = pdf.internal.getNumberOfPages()
        if marginTop + height > 272
          if pageNumber >= numberOfPages
            callbacks.onBeforeNewPage?()
            pdf.addPage()
            @_currentPage++
            callbacks.onAfterNewPage?()
          else
            @_currentPage = pageNumber+1
            pdf.setPage(@_currentPage)
          return {marginTop: 25, pageNumber: @_currentPage}
        return {marginTop: marginTop, pageNumber: pageNumber}
