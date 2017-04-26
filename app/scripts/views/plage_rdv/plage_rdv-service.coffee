"use strict"


angular.module('xin.plage_rdv_service', ['ui.calendar'])

  .factory "Calendar", ($q, $modal, DelayedEvent, uiCalendarConfig,
                        BackendWithoutInterceptor, guid) ->
    class Calendar
      constructor: (@siteId, @calendar, @editable) ->
        @eventSources = []
        @eventTitle = "Cliquez pour configurer la plage"
        if @calendar == "calendar"
          @eventTitle = "Plage à valider\nConfigurer sa durée et cliquez pour continuer"
        @_current_request = null
        @creneaux_inf = []
        @progressbar =
          value: 0
          status: null
          total_nb: 0
          value_nb: 0
        @errors =
          general: ""
          plages: []

      applyTemplate: (begin, end, repartition) ->
        defer = $q.defer()
        @_cleanErrors()
        @progressbar.status = "Ajout"
        @progressbar.value = 0
        @progressbar.total_nb = 0
        @progressbar.value_nb = 0
        beginDay = begin.dayOfYear()
        endDay = end.dayOfYear()
        for index in [beginDay..endDay]
          @progressbar.total_nb += repartition[moment().dayOfYear(index).day()].length
        promises = []
        for index in [beginDay..endDay]
          date = moment().dayOfYear(index)
          for source in repartition[date.day()]
            promises.push(@_createCreneauFromTemplate(source, date))
        $q.all(promises).then(
          () =>
            @_retrieveCreneaux()
            defer.resolve()
          (error) =>
            @_retrieveCreneaux()
            defer.resolve()
        )
        return defer.promise

      createUiConfig: ->
        uiConfig =
          lang: 'fr'
          timezone: 'local'
          allDaySlot: false
          slotDuration: '00:15:00'
          axisFormat: 'HH(:mm)'
          snapMinutes: 15
          height: 650
          firstHour: 8
          displayEventEnd: true
          handleWindowResize: true
          scrollTime: '08:00:00'
          minTime: '06:00:00'
          maxTime: '20:00:00'
          businessHours: true
          timeFormat: 'H:mm'
          header:
            left: ''
            center: ''
            right: ''
          editable: @editable
        if @calendar == "calendar"
          uiConfig.columnFormat = 'ddd D'
          uiConfig.buttonText =
            today: "Aujourd'hui"
            month: 'Mois'
            week: 'Semaine'
            day: 'Jour'
          uiConfig.header =
            left: 'agendaDay agendaWeek month'
            center: 'title'
            right: 'today prev,next'
          uiConfig.titleFormat =
            agendaWeek: "MMM YYYY"
            day: "DD MMM YYYY"
          uiConfig.defaultView = 'agendaWeek'
        else if @calendar == "day"
          uiConfig.columnFormat = 'Jour'
          uiConfig.defaultView = 'agendaDay'
        else if @calendar == "week"
          uiConfig.columnFormat = 'ddd'
          uiConfig.defaultView = 'agendaWeek'
        uiConfig.viewRender = if @calendar == "calendar" then @_retrieveCreneaux else undefined
        if @editable
          if @calendar == "calendar"
            uiConfig.eventClick = @_eventClickAddCreneaux
          else
            uiConfig.eventClick = @_eventClickConfigure
          uiConfig.dayClick = @_createPlageRdv
          uiConfig.eventResize = @_eventResize
          uiConfig.eventDrop = @_eventDrop
        else
          uiConfig.eventClick = @_eventClickShow
          uiConfig.dayClick = undefined
          uiConfig.eventResize = undefined
          uiConfig.eventDrop = undefined
        return uiConfig

      deletePeriodCren: ->
        defer = $q.defer()
        modalInstance = $modal.open(
          templateUrl: 'scripts/views/plage_rdv/modal/delete_period.html'
          controller: 'ModalInstanceDeleteCreneauPeriod'
        )
        modalInstance.result.then(
          (period) =>
            BackendWithoutInterceptor.all("sites/#{@siteId}/creneaux").remove(period).then(
              () =>
                @_retrieveCreneaux()
                defer.resolve()
              (error) -> defer.reject(error)
            )
          () -> defer.resolve()
        )
        return defer.promise

      deleteSelectedCren: ->
        defer = $q.defer()
        events = uiCalendarConfig.calendars[@calendar].fullCalendar('clientEvents')
        promises = []
        for creneau in events when creneau.type == 'creneau_a_detruire'
          creneau.type = 'creneau_detruit'
          promises.push(@_deleteCreneauById(creneau.guid))
        $q.all(promises).then(
          () =>
            @_updateCreneauxInf()
            defer.resolve()
          (error) -> defer.reject(error)
        )
        return defer.promise

      _cleanErrors: ->
        @errors =
          general: ""
          plages: []

      _configurePlage: (plage) ->
        # If create plageRDV, refetch event
        plage.backgroundColor = '#4EA9A0'
        if plage.end.diff(plage.start, 'minutes') <= 15
          plage.title = "#{plage.end.format('H:mm')} #{@eventTitle}"
        else
          plage.title = "#{@eventTitle}\n \
                         Nombre d'agents : #{plage.plage_guichets}\n \
                         Durée d'un créneau : #{plage.duree_creneau}\n \
                         Marge : #{plage.marge}"
        uiCalendarConfig.calendars[@calendar].fullCalendar('refetchEvents', plage._id)
        # And update element in eventSources
        for source in @eventSources or [] when source[0].guid == plage.guid
          source[0].plage_guichets = plage.plage_guichets
          source[0].duree_creneau = plage.duree_creneau
          source[0].marge = plage.marge
          source[0].marge_initiale = plage.marge_initiale
          source[0].backgroundColor = plage.backgroundColor
          source[0].title = plage.title

      _createCreneauxFromPlage: (plage) ->
        plage_payload =
          plage_debut: plage.start
          plage_fin: plage.end
          plage_guichets: plage.plage_guichets
          duree_creneau: plage.duree_creneau
          marge: plage.marge
          marge_initiale: plage.marge_initiale
        # Create new "creneau" in database and replace the "plage" with it
        BackendWithoutInterceptor.all("sites/#{@siteId}/creneaux").post(plage_payload).then(
          (creneaux) =>
            @_deletePlage(plage)
            for creneau in creneaux._items
              event = @_insertInCalendar(creneau)
              @eventSources.push([event])
          (error) => @_manageErrors(error)
        )

      _createCreneauFromTemplate: (source, date) ->
        defer = $q.defer()
        plage_payload =
          plage_debut: (moment(date).startOf('day')
                        .add(source.start.minutes(), 'minutes')
                        .add(source.start.hour(), 'hours'))
          plage_fin: (moment(date).startOf('day')
                        .add(source.end.minutes(), 'minutes')
                        .add(source.end.hour(), 'hours'))
          plage_guichets: source.plage_guichets
          duree_creneau: source.duree_creneau
          marge: source.marge
          marge_initiale: source.marge_initiale
        BackendWithoutInterceptor.all("sites/#{@siteId}/creneaux").post(plage_payload).then(
          (creneaux) =>
            @progressbar.value_nb += 1
            @progressbar.value = Math.ceil((@progressbar.value_nb * 100) / @progressbar.total_nb)
            defer.resolve()
          (error) =>
            msg = "Plage du #{moment(plage_payload.plage_debut).format('LLLL')}"
            @_manageErrors(error, msg)
            defer.reject()
        )
        return defer.promise

      _createPlageRdv: (date, jsEvent, view) =>
        if view.name == "agendaWeek" or view.name == "agendaDay"
          event =
            guid: guid()
            title: @eventTitle
            start: date
            end: moment(date).add(45, 'minutes')
            backgroundColor: 'orange'
            textColor: 'black'
            plage_guichets: 1
            duree_creneau: 45
            marge: 0
            marge_initiale: false
            type: "plage"
          @eventSources.push([event])

      _deleteCreneauById: (creneau_id) ->
        defer = $q.defer()
        BackendWithoutInterceptor.one("sites/#{@siteId}/creneaux/#{creneau_id}").remove().then(
          () =>
            uiCalendarConfig.calendars[@calendar].fullCalendar('removeEvents', (event) ->
              if creneau_id == event.guid
                return true
              else
                return false
            )
            defer.resolve()
          (error) -> defer.reject(error)
        )
        return defer.promise

      _deletePlage: (plage) ->
        for source, index in @eventSources when source[0].guid == plage.guid
          @eventSources.splice(index, 1)

      _eventClickAddCreneaux: (event) =>
        if event.type == 'plage'
          modalInstance = $modal.open(
            templateUrl: 'scripts/views/plage_rdv/modal/add_creneau.html'
            controller: 'ModalInstanceAddCreneauController'
            resolve:
              event: ->
                return event
          )
          modalInstance.result.then (created) =>
            @_cleanErrors()
            if created
              @_createCreneauxFromPlage(event)
            else
              @_deletePlage(event)
        # If we click on a "creneau" which is "non reserve", this "creneau" is marked
        # as "creneau_a_detruire"
        else if event.type == 'creneau' and event.reserve == false
          event.type = 'creneau_a_detruire'
          event.backgroundColor = 'orange'
          uiCalendarConfig.calendars[@calendar].fullCalendar('refetchEvents', event._id)
        # If we click on a "creneau" which is marked as "creneau_a_detruire", this
        # "creneau" is unmarked
        else if event.type == 'creneau_a_detruire' and event.reserve == false
          event.type = 'creneau'
          event.backgroundColor = '#4EA9A0'
          uiCalendarConfig.calendars[@calendar].fullCalendar('refetchEvents', event._id)
        # If we click on a "creneau" which is "reserve", we create new modal to view
        # informations about this "creneau"
        else if event.type == 'creneau' and event.reserve == true
          modalInstance = $modal.open(
            templateUrl: 'scripts/views/plage_rdv/modal/show_creneau.html'
            controller: 'ModalInstanceShowCreneauController'
            resolve:
              event: ->
                return event
          )

      _eventClickConfigure: (event) =>
        modalInstance = $modal.open(
          templateUrl: 'scripts/views/plage_rdv/modal/configure_plage.html'
          controller: 'ModalInstanceAddCreneauController'
          resolve:
            event: ->
              return event
        )
        modalInstance.result.then (created) =>
          if created
            @_configurePlage(event)
          else
            @_deletePlage(event)

      _eventClickShow: (event) ->
        modalInstance = $modal.open(
          templateUrl: 'scripts/views/plage_rdv/modal/show_plage.html'
          controller: 'ModalInstanceShowPlageController'
          resolve:
            event: ->
              return event
        )

      _eventDrop: (event, delta, revertFunc) =>
        if event.end.isAfter(event.start, 'days')
          revertFunc()
        else
          # And update element in eventSources
          for source in @eventSources or [] when source[0].guid == event.guid
            source[0].start = event._start
            source[0].end = event._end

      _eventResize: (event, delta, revertFunc) =>
        if event.end.isAfter(event.start, 'days')
          revertFunc()
        else
          duree = event.end.diff(event.start, 'minutes')
          if duree <= 15
            event.title = "#{event.end.format('H:mm')}"
          else
            event.title = "#{@eventTitle}\n \
                           Nombre d'agents : #{event.plage_guichets}\n \
                           Durée d'un créneau : #{event.duree_creneau}\n \
                           Marge : #{event.marge}"
          # And update element in eventSources
          for source in @eventSources or [] when source[0].guid == event.guid
            source[0].title = event.title
            source[0].start = event._start
            source[0].end = event._end

      _getDatesOnCalendarView: ->
        dates = null
        calendarView = uiCalendarConfig.calendars[@calendar].fullCalendar('getView')
        moment = uiCalendarConfig.calendars[@calendar].fullCalendar('getDate')
        switch calendarView.name
          when "agendaDay" then dates =
            begin: moment.startOf('day').format('YYYY-MM-DD[T]HH:mm:ss[Z]')
            end: moment.endOf('day').format('YYYY-MM-DD[T]HH:mm:ss[Z]')
          when "agendaWeek" then dates =
            begin: moment.startOf('week').format('YYYY-MM-DD[T]HH:mm:ss[Z]')
            end: moment.endOf('week').format('YYYY-MM-DD[T]HH:mm:ss[Z]')
          when "month" then dates =
            begin: moment.startOf('month').format('YYYY-MM-DD[T]HH:mm:ss[Z]')
            end: moment.endOf('month').format('YYYY-MM-DD[T]HH:mm:ss[Z]')
        return dates

      _insertInCalendar: (creneau) ->
        title = if creneau.marge then "Marge: #{creneau.marge}min" else ''
        start = moment(creneau.date_debut)
        end = moment(creneau.date_fin)
        event =
          guid: creneau.id
          title: if end.diff(start, "minutes") <= 15 then "#{end.format("H:mm")} #{title}" else title
          start: start
          end: end
          backgroundColor: if creneau.reserve then '#E83C1A' else '#4EA9A0'
          type: 'creneau'
          reserve: creneau.reserve
          marge: creneau.marge
          editable: false
        return event

      _manageErrors: (errors, plage) ->
        if errors.status == 400
          @errors.general = "Création d'un trop grand nombre de créneaux pour une seule requête."
          if plage?
            @errors.plages.push(plage)
        else
          @errors.general = "Une erreur inattendue s'est produite. \
                             Merci de contacter votre administrateur."

      _removeAllCreneauxFromCalendar: ->
        uiCalendarConfig.calendars[@calendar].fullCalendar('removeEvents')

      _retrieveCreneaux: =>
        delayedFilter = new DelayedEvent(1500)
        delayedFilter.triggerEvent =>
          @_removeAllCreneauxFromCalendar()
          eventsSourcesRessources = []
          @creneaux_inf = []
          @progressbar =
            status: "Chargement"
            value: 0
          current_request = guid()
          @_current_request = current_request
          dates = @_getDatesOnCalendarView()
          if not dates?
            return
          if dates.begin? and dates.end?
            url = "sites/#{@siteId}/creneaux?fq=date_debut:[#{dates.begin} TO #{dates.end}]"
            @_retrieveCreneauxLoop(url+"&per_page=20", current_request, eventsSourcesRessources)

      _retrieveCreneauxLoop: (link, current_request, eventsSourcesRessources) ->
        if link
          BackendWithoutInterceptor.all(link).getList().then (creneaux) =>
            if current_request == @_current_request
              @progressbar.value = Math.ceil((creneaux._meta.page * creneaux._meta.per_page * 100) / creneaux._meta.total)
              eventsSourcesRessources = eventsSourcesRessources.concat(creneaux.plain())
              @_retrieveCreneauxLoop(creneaux._links.next, current_request, eventsSourcesRessources)
        else
          if current_request == @_current_request
            eventsSources = []
            for creneau in eventsSourcesRessources
              event = @_insertInCalendar(creneau)
              eventsSources.push(event)
            uiCalendarConfig.calendars[@calendar].fullCalendar('addEventSource', eventsSources)
            @_updateCreneauxInf()
            @progressbar.status = null

      _updateCreneauxInf: ->
        @creneaux_inf = []
        events = uiCalendarConfig.calendars[@calendar].fullCalendar('clientEvents')
        for creneau in events when creneau.type in ['creneau', 'creneau_a_detruire']
          date = creneau.start
          newDate = true
          for elt in @creneaux_inf when elt.day is date.dayOfYear()
            newDate = false
            elt['creneaux'] += 1
            if creneau.reserve
              elt['reserve'] += 1
          if newDate
            @creneaux_inf.push({
              day: date.dayOfYear()
              date: date.format('Do MMMM YYYY')
              creneaux: 1
              reserve: if creneau.reserve then 1 else 0
            })
