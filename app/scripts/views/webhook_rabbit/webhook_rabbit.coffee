'use strict'

breadcrumbsGetWebhookDefer = undefined


angular.module('app.views.webhook_rabbit', ['app.settings', 'ngRoute', 'ui.bootstrap', 'xin.tools',
                                            'xin.listResource', 'xin.solrFilters', 'sc-toggle-switch',
                                            'xin.session', 'xin.backend', 'app.views.webhook_rabbit.modal'])
  .config ($routeProvider) ->
    $routeProvider
      .when '/orchestration-echanges-rabbit',
        templateUrl: 'scripts/views/webhook_rabbit/list_webhooks.html'
        controller: 'ListWebhooksRabbitController'
        reloadOnSearch: false
        breadcrumbs: 'Orchestration des échanges V2'
        routeAccess: true
      .when '/orchestration-echanges-rabbit/:queueId',
        templateUrl: 'scripts/views/webhook_rabbit/show_queue.html'
        controller: 'ShowQueueRabbitController'
        reloadOnSearch: false
        routeAccess: true,
        breadcrumbs: ngInject ($q) ->
          defer = $q.defer()
          breadcrumbsGetWebhookDefer = $q.defer()
          breadcrumbsGetWebhookDefer.promise.then (queue) ->
            defer.resolve([
              ['Orchestration des échanges V2', '#/orchestration-echanges-rabbit']
              [queue.queue, "#/orchestration-echanges-rabbit/#{queue.id}"]
            ])
          return defer.promise

  .controller 'ListWebhooksRabbitController', ($scope, session, Backend, DelayedEvent) ->
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
    $scope.resourceBackend = Backend.all('rabbit/queues')

    $scope.links = null

    $scope.dtLoadingTemplate = ->
      return {
        html: '<img src="images/spinner.gif">'
      }


  .controller 'ShowQueueRabbitController', ($scope, $route, $routeParams, $timeout,
                                      $interval, $location, $modal,
                                      Backend, session, SETTINGS,
                                      DelayedEvent) ->

    DATE_FORMAT_UTC = "YYYY-MM-DD[T]HH:mm:ss[Z]"

    INVALID_DATE_MESSAGE = 'Invalid date'

    MESSAGES_PER_PAGE = 100

    REFRESH_TIMER = 10000

    ALERT_CLASS_STATUS =
      'DONE': 'alert-success'
      'RETRY': 'alert-retry'
      'FAILURE': 'alert-danger'
      'DELETED': 'alert-warning'
      'SKIPPED': 'alert-info'
      'CANCELLED': 'alert-warning'

    DEFAULT_ALERT_CLASS = 'alert-info'

    STATUS_LIST =
      RETRY: 'RETRY'
      FAILURE: 'FAILURE'
      CANCELLED: 'CANCELLED'
      DELETED: 'DELETED'
      SKIPPED: 'SKIPPED'
      DONE: 'DONE'

    $scope.STATUS_LIST = STATUS_LIST

    $scope.info =
      message: ''
      show: false

    $scope.queue = {}
    $scope.replayAllDone = {}
    $scope.replayDone = {}
    $scope.deleteDone = {}
    $scope.cancelDone = {}
    $scope.showReplayAllButton = false

    # Load messages (status filters)
    $scope.RETRY = $routeParams.RETRY or false
    $scope.FAILURE = $routeParams.FAILURE or false
    $scope.CANCELLED = $routeParams.CANCELLED or false
    $scope.DELETED = $routeParams.DELETED or false
    $scope.SKIPPED = $routeParams.SKIPPED or false
    $scope.DONE = $routeParams.DONE or false

    $scope.links = null

    $scope.lookup =
      per_page: "12"
      page: "1"

    $scope.columnClassInfo = "col-md-12"

    $scope.messageCount =
      'DONE': 0
      'RETRY': 0
      'FAILURE': 0
      'DELETED': 0
      'SKIPPED': 0
      'CANCELLED': 0
      'ALL': 0

    queueRoute = "rabbit/queues/#{$routeParams.queueId}"
    messageRoute = queueRoute + "/messages"

    Backend.one(queueRoute).get().then(
      (queue) ->
        # breadcrumbs
        if breadcrumbsGetWebhookDefer?
          breadcrumbsGetWebhookDefer.resolve(queue)
          breadcrumbsGetWebhookDefer = undefined

        $scope.queue = queue.plain()
        for status of STATUS_LIST
          count = parseInt(queue.status_count[status])
          $scope.messageCount[status] = count
          $scope.messageCount['ALL'] += count
      (error) ->
        console.log(error)
        $scope.error =
          text: "Erreur lors de la récupération des données."
    )

    $scope.messages = undefined
    $scope.auto_refresh_messages = false
    $scope.auto_refresh_running = false

    # Load specific message (by ID)
    $scope.id_filter = null
    $scope.$watch 'id_filter', (value) ->
        loadMessages()

    loadMessages = ->
      $scope.auto_refresh_running = true
      # Clean id filter
      messages = []

      status_filters = ''
      for status of STATUS_LIST
        if $scope[status]
          status_filters += "?status=#{status}"

      hide_filters = [STATUS_LIST.RETRY, STATUS_LIST.FAILURE, STATUS_LIST.SKIPPED, STATUS_LIST.DONE]
      show_filters = [STATUS_LIST.CANCELLED, STATUS_LIST.DELETED]
      to_show = false
      for status of STATUS_LIST
        if status in hide_filters and $scope[status]
          to_show = false
          break
        if status in show_filters and $scope[status]
          to_show = !to_show
      $scope.showReplayAllButton = to_show

      messageUrl = messageRoute
      messageUrl += status_filters
      $scope.resourceBackend = Backend.all(messageUrl)

      $scope.computeResource = (current_scope) ->
        for resource in current_scope.resources
          # Pretty print the context
          try
            resource._context = JSON.stringify(JSON.parse(resource.json_context), null, 2)
          catch e
            # If the json is invalid, leave it as it is
            resource._invalid_context = true
            resource._context = resource.json_context
          resource._can_repeat = resource.status not in [STATUS_LIST.RETRY, STATUS_LIST.DONE]
          resource._can_delete = resource.status not in [STATUS_LIST.RETRY, STATUS_LIST.DONE, STATUS_LIST.SKIPPED, STATUS_LIST.DELETED]
          resource._can_cancel = resource.status not in [STATUS_LIST.RETRY, STATUS_LIST.CANCELLED, STATUS_LIST.DONE, STATUS_LIST.SKIPPED]
          resource._can_patch = resource.status not in [STATUS_LIST.RETRY, STATUS_LIST.DONE, STATUS_LIST.SKIPPED]
          resource._alert_class = ALERT_CLASS_STATUS[resource.status] || DEFAULT_ALERT_CLASS
          messages.push(resource)

        $scope.auto_refresh_running = false
        $scope.messages = angular.copy(messages)

    # loadMessages()
    stop = $interval(
      ->
        if $scope.auto_refresh_messages and not $scope.auto_refresh_running
          loadMessages()
      REFRESH_TIMER
    )
    $scope.$on('$destroy', -> $interval.cancel(stop))

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
      Backend.one("rabbit/queues/#{$routeParams.queueId}/messages/#{msgId}")
        .patch({'status': status}).then(
          (webhook) ->
            $route.reload()
          (error) ->
            console.log(error)
            $scope.error =
              text: "Erreur lors de la transaction."
      )

    cancelMessage = (msgId) ->
      message = "Êtes-vous sûr de vouloir annuler ce message ?"
      modalInstance = initConfirmModal(message)
      modalInstance.result.then(
        (result) ->
          if result == true
            processResultConfirmModal(msgId, STATUS_LIST.CANCELLED)
      )

    deleteMessage = (msgId) ->
      message = "Êtes-vous sûr de vouloir supprimer ce message ?"
      modalInstance = initConfirmModal(message)
      modalInstance.result.then(
        (result) ->
          if result == true
            processResultConfirmModal(msgId, STATUS_LIST.DELETED)
      )

    repeatMessage = (msgId) ->
      message = "Êtes-vous sûr de vouloir relancer le traitement de ce message ?"
      modalInstance = initConfirmModal(message)
      modalInstance.result.then(
        (result) ->
          if result == true
            processResultConfirmModal(msgId, STATUS_LIST.RETRY)
      )

    patchMessage = (msgId, context) ->
      modalInstance = $modal.open(
        templateUrl: 'scripts/views/webhook_rabbit/modal/patch_message.html'
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
          Backend.one("rabbit/queues/#{$routeParams.queueId}/messages/#{msgId}").patch({'json_context': context}).then(
            (webhook) ->
              $route.reload()
            (error) ->
              console.log(error)
              $scope.error =
                text: "Erreur lors de la modification."
          )
      )

    $scope.customOperation = (operation, data) ->
      switch operation
        when 'select'
          selectMessage(data['id'])
        when 'repeat'
          repeatMessage(data['id'])
        when 'cancel'
          cancelMessage(data['id'])
        when 'delete'
          deleteMessage(data['id'])
        when 'patch'
          patchMessage(data['id'], data['context'])

    processMessage = (msgId, status, callback, args = null) ->
      Backend.one("rabbit/queues/#{$routeParams.queueId}/messages/#{msgId}")
        .patch({'status': status}).then(
          (webhook) -> callback?(args)
          (error) ->
            console.log(error)
            $scope.error =
              text: "Erreur lors de la transaction."
        )

    ### Repeat message ###
    repeatOneMessage = (msgId, callback, args = null) ->
      processMessage(msgId, STATUS_LIST.RETRY, callback, args)

    ### Delete message ###
    deleteOneMessage = (msgId, callback, args = null) ->
      processMessage(msgId, STATUS_LIST.DELETED, callback, args)

    ### Cancel message ###
    cancelOneMessage = (msgId, callback, args = null) ->
      processMessage(msgId, STATUS_LIST.CANCELLED, callback, args)

    $scope.selected = []
    selectedCopy = []
    targetedMessagesIds = []
    excludedMessages = []
    repeatSelectedMessages = (msgId) ->
      if msgId?
        repeatOneMessage(msgId, repeatSelectedMessages, targetedMessagesIds.shift())
      else
        $route.reload()

    deleteSelectedMessages = (msgId) ->
      if msgId?
        deleteOneMessage(msgId, deleteSelectedMessages, targetedMessagesIds.shift())
      else
        $route.reload()

    cancelSelectedMessages = (msgId) ->
      if msgId?
        cancelOneMessage(msgId, cancelSelectedMessages, targetedMessagesIds.shift())
      else
        $route.reload()

    selectMessage = (msgId, force = false) ->
      index = selectedCopy.indexOf(msgId)
      if index == -1
        selectedCopy.push(msgId)
        $scope.selected[msgId] = true
      else if not force
        selectedCopy.splice(index, 1)
        $scope.selected[msgId] = false

    $scope.selectAll = (msgType) ->
      selectedCopy = []
      for msg in $scope.messages
        $scope.selected[msg.id] = false
        switch msgType
          when 'deletable'
            if msg._can_delete
              selectMessage(msg.id, true)
          when 'cancellable'
            if msg._can_cancel
              selectMessage(msg.id, true)
          when 'repeatable'
            if msg._can_repeat
              selectMessage(msg.id, true)

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
          targetedMessagesIds = []
          excludedMessages = []
          for id in selectedCopy
            msg = $scope.messages.filter((elt) -> elt.id == id)[0]
            switch action
              when 'delete'
                if msg._can_delete
                  targetedMessagesIds.push(msg.id)
                else
                  excludedMessages.push(msg)
              when 'cancel'
                if msg._can_cancel
                  targetedMessagesIds.push(msg.id)
                else
                  excludedMessages.push(msg)
              when 'repeat'
                if msg._can_repeat
                  targetedMessagesIds.push(msg.id)
                else
                  excludedMessages.push(msg)
          # Run action
          switch action
            when 'delete'
              deleteSelectedMessages(targetedMessagesIds.shift())
            when 'cancel'
              cancelSelectedMessages(targetedMessagesIds.shift())
            when 'repeat'
              repeatSelectedMessages(targetedMessagesIds.shift())
          # Show Excluded Messages
          if excludedMessages.length > 0
            modalInstance = $modal.open(
              templateUrl: 'scripts/views/webhook_rabbit/modal/excluded_messages.html'
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
      for status of STATUS_LIST
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
          url = "rabbit/queues/#{$routeParams.queueId}/messages/#{status_filter}?per_page=#{MESSAGES_PER_PAGE}"
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
        Backend.one("rabbit/queues/#{$routeParams.queueId}/messages/#{message.id}")
          .patch({'status': STATUS_LIST.RETRY}).then(
            () -> replayMessage()
            (error) -> throw error
          )
      else
        $route.reload()
