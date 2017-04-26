'use strict'

angular.module('app.views.remise_titres.barcode_scanner', [])
.directive 'barcodeScanner', ($window) ->
  'ngInject'
  {
    restrict: 'AE'
    scope:
      onScan: '='
    link: (scope) ->
      ENTER_KEY_CODE = 13

      isValidKeyCode = (keyCode) ->
        keyCode == ENTER_KEY_CODE or keyCode >= 32 and keyCode <= 255

      isBufferedFromScan = (keyCodes) ->
        _.last(keyCodes) == ENTER_KEY_CODE

      keyCodesWithoutEnterKey = (keyCodes) ->
        _.without(keyCodes, ENTER_KEY_CODE)

      isNotEmpty = (keyCodes) ->
        keyCodes.length > 0

      keyCodesToString = (keyCodes) ->
        keyCodes
          .map((keyCode) -> String.fromCharCode(keyCode))
          .join('')

      windowElt = angular.element($window)

      keyCodes$ = Rx.Observable.fromEvent(windowElt, 'keydown')
        .pluck('keyCode')
        .filter(isValidKeyCode)

      # Emits a buffer of `keyCodes` whenever some time has spent and no `keyCode` has been emitted.
      # So we can differentiate scans from manual inputs.
      keyCodesBuffers$ = keyCodes$.buffer(keyCodes$.debounce(50))

      keyCodesBuffers$
        .filter(isBufferedFromScan)
        .map(keyCodesWithoutEnterKey)
        .filter(isNotEmpty)
        .map(keyCodesToString)
        .subscribe(scope.onScan)
  }

