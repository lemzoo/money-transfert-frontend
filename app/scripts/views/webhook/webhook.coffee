'use strict'

breadcrumbsGetWebhookDefer = undefined


angular.module('app.views.webhook', ['app.settings', 'ngRoute', 'ui.bootstrap',
                                     'xin.listResource', 'xin.tools', 'sc-toggle-switch',
                                     'xin.session', 'xin.backend', 'app.views.webhook.modal'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/orchestration-echanges',
        templateUrl: 'scripts/views/webhook/list_webhooks.html'
        controller: 'ListWebhooksController'
        reloadOnSearch: false
        breadcrumbs: 'Orchestration des échanges'
        routeAccess: true
      .when '/orchestration-echanges/:queueId',
        templateUrl: 'scripts/views/webhook/show_queue.html'
        controller: 'ShowQueueController'
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          breadcrumbsDefer = $q.defer()
          breadcrumbsGetWebhookDefer = $q.defer()
          breadcrumbsGetWebhookDefer.promise.then (queue) ->
            breadcrumbsDefer.resolve([
              ['Orchestration des échanges', '#/orchestration-echanges']
              [queue.queue, '#/orchestration-echanges/' + queue.id]
            ])
          return breadcrumbsDefer.promise

  .controller 'ListWebhooksController', ($scope, session, Backend, DelayedEvent) ->
    $scope.lookup = {}
    # Filter field is trigger after 500ms of inactivity
    delayedFilter = new DelayedEvent(500)
    $scope.filterField = ''
    $scope.$watch 'filterField', (filterValue) ->
      delayedFilter.triggerEvent ->
        if filterValue? and filterValue != ''
          $scope.lookup.q = filterValue
        else if $scope.lookup.q?
          delete $scope.lookup.q
    $scope.resourceBackend = Backend.all('broker/queues')

    $scope.links = null

    $scope.dtLoadingTemplate = ->
      return {
        html: '<img src="images/spinner.gif">'
      }


  .controller 'ShowQueueController', ($scope, $route, $routeParams, $timeout,
                                      $interval, $location, $modal,
                                      Backend, BackendWithoutInterceptor,
                                      session, SETTINGS,
                                      DelayedEvent) ->
    $scope.info =
      message: ''
      show: false
    $scope.queue = {}
    $scope.replayAllDone = {}
    $scope.replayDone = {}
    $scope.deleteDone = {}
    $scope.cancelDone = {}
    $scope.showReplayAllButton = false

    # Load messages (to, from and status filters)
    $scope.from = $routeParams.from or ''
    $scope.to = $routeParams.to or ''
    $scope.READY = $routeParams.ready or false
    $scope.FAILURE = $routeParams.failure or false
    $scope.CANCELLED = $routeParams.cancelled or false
    $scope.DELETED = $routeParams.deleted or false
    $scope.SKIPPED = $routeParams.skipped or false
    $scope.DONE = $routeParams.done or false

    STATUS_LIST =
      READY: 'READY'
      FAILURE: 'FAILURE'
      CANCELLED: 'CANCELLED'
      DELETED: 'DELETED'
      SKIPPED: 'SKIPPED'
      DONE: 'DONE'

    Backend.one('broker/queues/' + $routeParams.queueId).get().then(
      (queue) ->
        # breadcrums
        if breadcrumbsGetWebhookDefer?
          breadcrumbsGetWebhookDefer.resolve(queue)
          breadcrumbsGetWebhookDefer = undefined

        $scope.queue = queue.plain()
      (error) -> throw error
    )

    $scope.messages = undefined
    $scope.auto_refresh_messages = false
    $scope.auto_refresh_running = false

    getActiveStatus = () ->
      status = []
      if $scope.READY
        status.push(STATUS_LIST.READY)
      if $scope.FAILURE
        status.push(STATUS_LIST.FAILURE)
      if $scope.CANCELLED
        status.push(STATUS_LIST.CANCELLED)
      if $scope.DELETED
        status.push(STATUS_LIST.DELETED)
      if $scope.SKIPPED
        status.push(STATUS_LIST.SKIPPED)
      if $scope.DONE
        status.push(STATUS_LIST.DONE)
      return status

    # Load specific message (by ID)
    $scope.selectId = undefined
    $scope.id_filter = null
    delayedFilterMsgId = new DelayedEvent(1000)
    $scope.$watch 'id_filter', (value) ->
      delayedFilterMsgId.triggerEvent ->
        if value? and value != ''
          route = "broker/queues/#{$routeParams.queueId}/messages/#{value}"
          BackendWithoutInterceptor.one(route).get().then(
            (msg) ->
              if msg.status in getActiveStatus()
                # Pretty print the context
                try
                  msg._context = JSON.stringify(JSON.parse(msg.json_context), null, 2)
                catch e
                  # If the json is invalid, leave it as it is
                  msg._invalid_context = true
                  msg._context = msg.json_context
                msg._can_repeat = msg.status != STATUS_LIST.READY or msg.next_run
                msg._can_delete = msg.status != STATUS_LIST.DELETED
                msg._can_cancel = msg.status != STATUS_LIST.CANCELLED
                msg._can_patch = msg.status != STATUS_LIST.DONE
                $scope.messages = [msg]
              else
                $scope.messages = []
            (error) ->
              $scope.messages = []
          )
        else
          loadMessages()

    base_message_url = "broker/queues/#{$routeParams.queueId}/messages?per_page=100"

    $scope.updateFilters = ->
      search = {}
      if $scope.from != ""
        search["from"] = moment($scope.from).utc().format("YYYY-MM-DD[T]HH:mm:ss[Z]")
      if $scope.to
        search["to"] = moment($scope.to).utc().format("YYYY-MM-DD[T]HH:mm:ss[Z]")
      if $scope.READY
        search["ready"] = $scope.READY
      if $scope.FAILURE
        search["failure"] = $scope.FAILURE
      if $scope.CANCELLED
        search["cancelled"] = $scope.CANCELLED
      if $scope.DELETED
        search["deleted"] = $scope.DELETED
      if $scope.SKIPPED
        search["skipped"] = $scope.SKIPPED
      if $scope.DONE
        search["done"] = $scope.DONE
      $location.search(search)

    loadMessages = ->
      $scope.auto_refresh_running = true
      # Clean id filter
      selectId = []
      to_param = ''
      if $scope.to != ''
        to_utc = moment($scope.to).utc().format("YYYY-MM-DD[T]HH:mm:ss[Z]")
        if to_utc != 'Invalid date'
          to_param = "&to=" + encodeURIComponent(to_utc)

      from_param = ''
      if $scope.from != ''
        from_utc = moment($scope.from).utc().format("YYYY-MM-DD[T]HH:mm:ss[Z]")
        if from_utc != 'Invalid date'
          from_param = "&from=" + encodeURIComponent(from_utc)

      status_filters = ''
      for key, status of STATUS_LIST
        if $scope[status]
          status_filters += "&status=#{status}"

      hide_filters = [STATUS_LIST.READY, STATUS_LIST.FAILURE, STATUS_LIST.SKIPPED, STATUS_LIST.DONE]
      show_filters = [STATUS_LIST.CANCELLED, STATUS_LIST.DELETED]
      to_show = false
      for key, status of STATUS_LIST
        if status in hide_filters and $scope[status]
          to_show = false
          break
        if status in show_filters and $scope[status]
          to_show = !to_show
        $scope.showReplayAllButton = to_show

      message_url = base_message_url
      message_url += status_filters
      message_url += from_param
      message_url += to_param
      Backend.all(message_url).getList().then (messages) ->
        $scope.messages = []
        for msg, index in messages
          # Pretty print the context
          try
            msg._context = JSON.stringify(JSON.parse(msg.json_context), null, 2)
          catch e
            # If the json is invalid, leave it as it is
            msg._invalid_context = true
            msg._context = msg.json_context
          msg._can_repeat = msg.status != STATUS_LIST.READY or msg.next_run
          msg._can_delete = msg.status != STATUS_LIST.DELETED
          msg._can_cancel = msg.status != STATUS_LIST.CANCELLED
          msg._can_patch = msg.status != STATUS_LIST.DONE
          $scope.messages.push(msg)
          selectId.push(
            id: msg.id
            libelle: msg.id
          )

        $scope.auto_refresh_running = false
        $scope.selectId = angular.copy(selectId)

    # loadMessages()
    stop = $interval(
      ->
        if $scope.auto_refresh_messages and not $scope.auto_refresh_running
          loadMessages()
      10000
    )
    $scope.$on('$destroy', -> $interval.cancel(stop))

    $scope.$watch 'from', (value) ->
      if value == null or (value and moment(value).utc().format("YYYY-M-DTHH:mm:ssZ") != 'Invalid date')
        $scope.updateFilters()

    $scope.$watch 'to', (value) ->
      if value == null or (value and moment(value).utc().format("YYYY-M-DTHH:mm:ssZ") != 'Invalid date')
        $scope.updateFilters()

    $scope.pauseQueue = ->
      Backend.one('broker/queues/' + $scope.queue.id + '/pause').post().then(
        (queue) ->
          $route.reload()
        (error) ->
          throw error
      )
    $scope.resumeQueue = ->
      Backend.one('broker/queues/' + $scope.queue.id + '/resume').post().then(
        (queue) ->
          $route.reload()
        (error) ->
          throw error
      )


    initConfirmModal = (message) ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return message
          sub_message: ->
            return ""
      )
      return modalInstance


    processResultConfirmModal = (msgId, status) ->
      Backend.one("broker/queues/#{$routeParams.queueId}/messages/#{msgId}")
        .patch({'status': status}).then(
          (webhook) ->
            $route.reload()
          (error) ->
            console.log(error)
            $scope.error =
              text: "Erreur lors de la transaction."
      )


    $scope.cancelMessage = (msgId) ->
      message = "Êtes-vous sûr de vouloir annuler ce message ?"
      modalInstance = initConfirmModal(message)
      modalInstance.result.then(
        (result) ->
          if result == true
            processResultConfirmModal(msgId, STATUS_LIST.CANCELLED)
      )


    $scope.deleteMessage = (msgId) ->
      message = "Êtes-vous sûr de vouloir supprimer ce message ?"
      modalInstance = initConfirmModal(message)
      modalInstance.result.then(
        (result) ->
          if result == true
            processResultConfirmModal(msgId, STATUS_LIST.DELETED)
      )


    $scope.repeatMessage = (msgId) ->
      message = "Êtes-vous sûr de vouloir relancer le traitement de ce message ?"
      modalInstance = initConfirmModal(message)
      modalInstance.result.then(
        (result) ->
          if result == true
            processResultConfirmModal(msgId, STATUS_LIST.READY)
      )


    $scope.patchMessage = (msgId, context) ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/webhook/modal/patch_message.html'
        controller: 'ModalInstancePatchMessageController'
        backdrop: false
        keyboard: false
        resolve:
          msg_id: ->
            return msgId
          context: ->
            return context
      )
      modalInstance.result.then(
        (context) ->
          Backend.one('broker/queues/' + $routeParams.queueId + '/messages/' + msgId).patch({'json_context': context}).then(
            (webhook) ->
              $route.reload()
            (error) ->
              throw error
          )
      )


    processMessage = (msgId, status, callback, args = null) ->
      Backend.one("broker/queues/#{$routeParams.queueId}/messages/#{msgId}")
        .patch({'status': status}).then(
          (webhook) -> callback?(args)
          (error) ->
            console.log(error)
            $scope.error =
              text: "Erreur lors de la transaction."
        )


    ### Cancel message ###
    cancelMessage = (msgId, callback, args = null) ->
      processMessage(msgId, STATUS_LIST.CANCELLED, callback, args)

    ### Repeat message ###
    repeatMessage = (msgId, callback, args = null) ->
      processMessage(msgId, STATUS_LIST.READY, callback, args)

    ### Delete message ###
    deleteMessage = (msgId, callback, args = null) ->
      processMessage(msgId, STATUS_LIST.DELETED, callback, args)

    $scope.selected = []
    selectedCopy = []
    targetedMessages = []
    excludedMessages = []
    repeatSelectedMessages = (msgId) ->
      if msgId?
        repeatMessage(msgId, repeatSelectedMessages, targetedMessages.shift())
      else
        $route.reload()

    deleteSelectedMessages = (msgId) ->
      if msgId?
        deleteMessage(msgId, deleteSelectedMessages, targetedMessages.shift())
      else
        $route.reload()

    cancelSelectedMessages = (msgId) ->
      if msgId?
        cancelMessage(msgId, cancelSelectedMessages, targetedMessages.shift())
      else
        $route.reload()

    $scope.askRepeatMessage = (msgId) ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return "Êtes-vous sûr de vouloir relancer le traitement de ce message ?"
          sub_message: ->
            return ""
      )
      modalInstance.result.then (result) ->
        if result == true
          callback = ->
            $route.reload()
          repeatMessage(msgId, callback)

    $scope.select = (msgId, force = false) ->
      index = selectedCopy.indexOf(msgId)
      if index == -1
        selectedCopy.push(msgId)
      else if not force
        selectedCopy.splice(index, 1)

    $scope.selectAll = (msgType) ->
      selectedCopy = []
      for msg in $scope.messages
        $scope.selected[msg.id] = false
        switch msgType
          when 'deletable'
            if msg._can_delete
              $scope.selected[msg.id] = true
              $scope.select(msg.id, true)
          when 'cancellable'
            if msg._can_cancel
              $scope.selected[msg.id] = true
              $scope.select(msg.id, true)
          when 'repeatable'
            if msg._can_repeat
              $scope.selected[msg.id] = true
              $scope.select(msg.id, true)


    $scope.doOnSelectedMessages = (action) ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            switch action
              when 'delete'
                return "Êtes-vous sûr de vouloir supprimer les messages sélectionnés ?"
              when 'cancel'
                return "Êtes-vous sûr de vouloir annuler les messages sélectionnés ?"
              when 'repeat'
                return "Êtes-vous sûr de vouloir rejouer les messages sélectionnés ?"
          sub_message: ->
            return ""
      )
      modalInstance.result.then (result) ->
        if result
          # Find Targeted and Excluded Messages
          targetedMessages = []
          excludedMessages = []
          for id in selectedCopy
            msg = $scope.messages.filter((elt) ->
              if elt.id == id
                return elt
            )[0]
            switch action
              when 'delete'
                if msg._can_delete
                  targetedMessages.push(msg.id)
                else
                  excludedMessages.push(msg)
              when 'cancel'
                if msg._can_cancel
                  targetedMessages.push(msg.id)
                else
                  excludedMessages.push(msg)
              when 'repeat'
                if msg._can_repeat
                  targetedMessages.push(msg.id)
                else
                  excludedMessages.push(msg)
          # Run action
          switch action
            when 'delete'
              deleteSelectedMessages(targetedMessages.shift())
            when 'cancel'
              cancelSelectedMessages(targetedMessages.shift())
            when 'repeat'
              repeatSelectedMessages(targetedMessages.shift())
          # Show Excluded Messages
          if excludedMessages.length > 0
            modalInstance = $modal.open(
              templateUrl: 'scripts/views/webhook/modal/excluded_messages.html'
              controller: 'ModalInstanceExcludedMessagesController'
              backdrop: false
              keyboard: false
              resolve:
                excludedMessages: ->
                  return excludedMessages
            )
        else
          switch action
            when 'delete'
              $scope.deleteDone.end?()
            when 'cancel'
              $scope.cancelDone.end?()
            when 'repeat'
              $scope.replayDone.end?()


    messagesToReplay = []
    $scope.repeatAllMessages = () ->
      messagesToReplay = []
      status_filter = ''
      for status in STATUS_LIST
        if $scope[status]
          status_filter = status
          break
      modalInstance = $modal.open(
        templateUrl: 'scripts/xin/modal/modal.html'
        controller: 'ModalInstanceConfirmController'
        backdrop: false
        keyboard: false
        resolve:
          message: ->
            return "Êtes-vous sûr de vouloir rejouer tous les messages au statut #{status_filter} ?"
          sub_message: ->
            return ""
      )
      modalInstance.result.then (result) ->
        if result
          url = "broker/queues/#{$routeParams.queueId}/messages/#{status_filter}?per_page=100"
          getMessages(url)
        else
          $scope.replayAllDone.end?()

    getMessages = (url) ->
      Backend.all(url).getList().then (messages)->
        messagesToReplay = messagesToReplay.concat(messages)
        if messages._links.next?
          getMessages(messages._links.next)
        else
          replayMessage()

    replayMessage = ->
      message = messagesToReplay.pop()
      if message?
        Backend.one("broker/queues/#{$routeParams.queueId}/messages/#{message.id}")
          .patch({'status': STATUS_LIST.READY}).then(
            () -> replayMessage()
            (error) -> throw error
          )
      else
        $route.reload()
