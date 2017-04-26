'use strict'


angular.module('xin.pdf.remise_titres', [])
  .factory 'RemiseTitresPdf', ($filter, $q, Backend, SETTINGS, Pdf) ->
    class RemiseTitrePdf extends Pdf
      constructor: (@_usager, @_timbre) ->
        super
        @_SITUATION_FAMILIALE =
          'CELIBATAIRE' : 'Célibataire'
          'DIVORCE' : 'Divorcé(e)'
          'MARIE' : 'Marié(e)'
          'CONCUBIN' : 'Concubin(e)'
          'SEPARE' : 'Séparé(e)'
          'VEUF' : 'Veuf(ve)'
          'PACSE' : 'Pacsé(e)'
        @_marianne = {}

      generate: (language = "") ->
        @_convertImgToBase64URL("/images/logo-de-la-republique-francaise2.png", @_init)

      _init: (base64Img, width, height) =>
        @_pdf = @_newPdf()
        @_pdf.addImage(base64Img, 'PNG', 81, 20, 48, 28)
        @_generate()
        @_save("remise_titres.pdf")

      _generate: () ->
        @_pdf.setFontSize(10)
        @_pdf.setFontType('bold')
        text = "CONFIRMATION DE REMISE DE TITRE POUR ETRANGER"
        width = @_ptTomm(@_pdf.getTextDimensions(text).w)
        @_pdf.text(106-width/2, 60, text)

        # Positions
        x = 20
        y = 91
        @_pdf.setFontSize(11)
        @_pdf.setFontType('normal')

        # Etat Civil
        title = "ETAT CIVIL"
        text = @_pdf.splitTextToSize("Le présent document certifie que le titre pour étranger a bien été remis à l’usager nommé ci-dessous.", 170)
        @_pdf.text(x, y, text)
        y += 12
        fields = [
          @_getTextInline("N° Etranger", @_usager.identifiant_agdref)
          @_getBlank()
          @_getTextInline("Nom", @_usager.nom)
          @_getTextInline("Nom d'usage", @_usager.nom_usage)
          @_getTextInline("Prénom", @_usager.prenoms[0])
          @_getTextInline("Sexe", if @_usager.sexe == 'M' then 'Masculin' else 'Féminin')
          @_getBlank()
          @_getDate("Né(e) le", @_usager.date_naissance, @_usager.date_naissance_approximative)
          @_getTextInline("A", "#{@_usager.ville_naissance}, #{@_usager.pays_naissance.libelle}")
          @_getTextInline("Nationalité", @_usager.nationalites[0].libelle)
        ]
        y = @_addThumbnail(title, fields, x, y)
        y += 15
        # Consommation du timbre
        title = "CONSOMMATION DU TIMBRE"
        @_pdf.setFontSize(11)
        text = @_pdf.splitTextToSize("La taxe a été réglée par consommation du timbre fiscal dont les informations sont rappelées ci-dessous.", 170)
        @_pdf.text(x, y, text)
        y += 12
        fields = [
          @_getTextInline("Numéro du timbre", @_timbre.numero)
          @_getTextInline("Montant", "#{@_timbre.montant} €")
          @_getDate("Date de consommation", @_timbre.date)
        ]
        y = @_addThumbnail(title, fields, x, y)

      _checkEndPage: (marginTop, height) ->
        return marginTop + height > 272

      _getSubtitle: (value) ->
        return {"SUBTITLE": value}

      _getSubSubtitle: (value) ->
        return {"SUBSUBTITLE": value}

      _getLine: () ->
        return {"LINE": ''}

      _getBlank: () ->
        return {"BLANK": ''}

      _getCheckBox: (value) ->
        return {"CHECKBOX": value}

      _getPhoto: (value) ->
        return {"PHOTO": value}

      _getTextInline: (key, value) ->
        if not value? then return {"EMPTY": ''}
        if typeof(value) == 'boolean'
          value = if value then 'Oui' else 'Non'
        return {"TEXTINLINE": "#{key}: #{value}"}

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
        @_pdf.setFontSize(10)
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
          else if field['BLANK']?
            if pos isnt position['left']
              pos = position['left']
              lines += 1
            lines += 1
          else if field['LINE']?
            if pos isnt position['left']
              pos = position['left']
              lines += 1
            @_pdf.line(left + 15, top + (lines * 5), right - 15, top + (lines * 5))
            lines += 1
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
          else if field['CHECKBOX']?
            if pos isnt position['left']
              pos = position['left']
              lines += 1
            text = field['CHECKBOX']
            @_pdf.rect(pos, top + (lines * 5) - 2, 2, 2)
            @_pdf.text(pos + 3, top + (lines * 5), text)
            lines += 1
          else if field['TEXTINLINE']?
            text = field['TEXTINLINE']
            if pos isnt position['left']
              pos = position['left']
              lines += 1
            @_pdf.text(pos, top + (lines * 5), text)
            lines += 1
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
