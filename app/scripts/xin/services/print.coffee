'use strict'


angular.module('xin.print', [])

  .directive 'printDirective', () ->
    restrict: 'A'

    link: (scope, elem, attrs) ->
      elem.on('click', ->
        elemToPrint = document.getElementById(attrs.printElementId)
        if (elemToPrint)
          printElement(elemToPrint)
      )

      printSection = document.getElementById('printSection')
      # if there is no printing section, create one
      if (!printSection)
        printSection = document.createElement('div')
        printSection.id = 'printSection'
        document.body.appendChild(printSection)

      printElement = (elem) ->
        # clones the element you want to print
        domClone = elem.cloneNode(true)
        printSection.appendChild(domClone)
        window.print()
        printSection.innerHTML = ''
