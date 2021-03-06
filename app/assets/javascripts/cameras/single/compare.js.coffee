imagesCompare = undefined

window.sendAJAXRequest = (settings) ->
  token = $('meta[name="csrf-token"]')
  if token.size() > 0
    headers =
      "X-CSRF-Token": token.attr("content")
    settings.headers = headers
  xhrRequestChangeMonth = $.ajax(settings)

initCompare = ->
  imagesCompareElement = $('.js-img-compare').imagesCompare()
  imagesCompare = imagesCompareElement.data('imagesCompare')
  events = imagesCompare.events()

  imagesCompare.on events.changed, (event) ->
    true

getFirstLastImages = (image_id, query_string, reload, setDate) ->
  data =
    api_id: Evercam.User.api_id
    api_key: Evercam.User.api_key

  onError = (jqXHR, status, error) ->
    false

  onSuccess = (response, status, jqXHR) ->
    snapshot = response
    if query_string.indexOf("nearest") > 0 && response.snapshots.length > 0
      snapshot = response.snapshots[0]
    if snapshot.data isnt undefined
      $("##{image_id}").attr("src", snapshot.data)
      if setDate
        d = new Date(snapshot.created_at*1000)
        before_month = d.getUTCMonth()+1
        before_year = d.getUTCFullYear()
        string_date = "#{before_month}/#{d.getUTCDate()}/#{before_year} #{d.getUTCHours()}:#{d.getUTCMinutes()}"
        $('#calendar-before').datetimepicker({value: string_date})
      initCompare() if reload
    else
      Notification.show("No image found")

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    type: 'GET'
    url: "#{Evercam.API_URL}cameras/#{Evercam.Camera.id}/recordings/snapshots#{query_string}"
  sendAJAXRequest(settings)

handleTabOpen = ->
  $('.nav-tab-compare').on 'shown.bs.tab', ->
    initCompare()
    updateURL()

updateURL = ->
  url = "#{Evercam.request.rootpath}/compare"
  query_string = ""
  if $("#txtbefore").val() isnt ""
    query_string = "?before=#{moment.utc($("#txtbefore").val()).toISOString()}"
  if $("#txtafter").val() isnt ""
    if query_string is ""
      query_string = "?after=#{moment.utc($("#txtafter").val()).toISOString()}"
    else
      query_string = "#{query_string}&after=#{moment.utc($("#txtafter").val()).toISOString()}"

  url = "#{url}#{query_string}"
  if history.replaceState
    window.history.replaceState({}, '', url)

getQueryStringByName = (name) ->
  name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]')
  regex = new RegExp('[\\?&]' + name + '=([^&#]*)')
  results = regex.exec(location.search)
  if results == null
    null
  else
    decodeURIComponent(results[1].replace(/\+/g, ' '))

clickOnEmbed = ->
  $(".images-compare-embed-code").on "click", ->
    if !Evercam.Camera.is_public
      Notification.show("Embedding is not working for private cameras.")
    after = " #{getQueryStringByName("after")}"
    before = " #{getQueryStringByName("before")}"
    after = "" if after is " null"
    before = "" if before is " null"
    $("#txtEmbedCode").val("<div id='evercam-compare'></div><script src='#{window.location.origin}/assets/evercam_compare.js' class='#{Evercam.Camera.id}#{before}#{after}'></script>")
    $("#txtEmbedCode").select();
    copyToClipboard(document.getElementById("txtEmbedCode"))

copyToClipboard = (elem) ->
  targetId = '_hiddenCopyText_'
  isInput = elem.tagName == 'INPUT' or elem.tagName == 'TEXTAREA'
  origSelectionStart = undefined
  origSelectionEnd = undefined
  if isInput
    target = elem
    origSelectionStart = elem.selectionStart
    origSelectionEnd = elem.selectionEnd
  else
    target = document.getElementById(targetId)
    if !target
      target = document.createElement('textarea')
      target.style.position = 'absolute'
      target.style.left = '-9999px'
      target.style.top = '0'
      target.id = targetId
      document.body.appendChild target
    target.textContent = elem.textContent
  currentFocus = document.activeElement
  target.focus()
  target.setSelectionRange 0, target.value.length
  succeed = undefined
  try
    succeed = document.execCommand('copy')
    Notification.show("Embed code copied.")
  catch e
    succeed = false
  if currentFocus and typeof currentFocus.focus == 'function'
    currentFocus.focus()
  if isInput
    elem.setSelectionRange origSelectionStart, origSelectionEnd
  else
    target.textContent = ''
  succeed

HighlightDaysInMonth = (query_string, year, month) ->
  data = {}
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onError = (response, status, error) ->
    false

  onSuccess = (response, status, jqXHR) ->
    removeCurrentDateHighlight(query_string)
    removeCurrentHourHighlight(query_string)
    hideBeforeAfterLoadingAnimation(query_string)
    for day in response.days
      HighlightBeforeAfterDay(query_string, year, month, day)

  settings =
    cache: true
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/json charset=utf-8"
    type: 'GET'
    url: "#{Evercam.MEDIA_API_URL}cameras/#{Evercam.Camera.id}/recordings/snapshots/#{year}/#{month}/days"

  sendAJAXRequest(settings)

HighlightBeforeAfterDay = (query_string, before_year, before_month, before_day) ->
  beforeDays = $("##{query_string} .xdsoft_datepicker table td[class*='xdsoft_date'] div")
  beforeDays.each ->
    beforeDay = $(this)
    if !beforeDay.parent().hasClass('xdsoft_other_month')
      iDay = parseInt(beforeDay.text())
      if before_day == iDay
        beforeDay.parent().addClass 'xdsoft_current'

HighlightSnapshotHour = (query_string, year, month, date) ->
  data = {}
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onError = (jqXHR, status, error) ->
    false

  onSuccess = (response, status, jqXHR) ->
    removeCurrentHourHighlight(query_string)
    hideBeforeAfterLoadingAnimation(query_string)
    for hour in response.hours
      HighlightBeforeAfterHour(query_string, year, month, date, hour)

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/json charset=utf-8"
    type: 'GET'
    timeout: 15000
    url: "#{Evercam.MEDIA_API_URL}cameras/#{Evercam.Camera.id}/recordings/snapshots/#{year}/#{(month)}/#{date}/hours"

  sendAJAXRequest(settings)

HighlightBeforeAfterHour = (query_string, before_year, before_month, before_day, before_hour) ->
  beforeHours = $("##{query_string} .xdsoft_timepicker [class*='xdsoft_time']")
  beforeHours.each ->
    beforeHour = $(this)
    iHour = parseInt(beforeHour.text())
    if before_hour == iHour
      beforeHour.addClass 'xdsoft_current'

removeCurrentHourHighlight = (query_string) ->
  beforeHours = $("##{query_string} .xdsoft_timepicker [class*='xdsoft_time']")
  beforeHours.removeClass 'xdsoft_current'

removeCurrentDateHighlight = (query_string) ->
  beforeDays = $("##{query_string} .xdsoft_datepicker table td[class*='xdsoft_date']")
  beforeDays.removeClass 'xdsoft_current'

showBeforeAfterLoadingAnimation = (query_string) ->
  $("##{query_string} .xdsoft_datepicker").addClass 'opacitypoint5'
  $("##{query_string} .xdsoft_timepicker").addClass 'opacitypoint5'

hideBeforeAfterLoadingAnimation = (query_string) ->
  $("##{query_string} .xdsoft_datepicker").removeClass 'opacitypoint5'
  $("##{query_string} .xdsoft_timepicker").removeClass 'opacitypoint5'

window.initializeCompareTab = ->
  $("#txtEmbedCode").val("<div id='evercam-compare'></div><script src='#{window.location.origin}/assets/evercam_compare.js' class='#{Evercam.Camera.id}'></script>")
  getFirstLastImages("compare_before", "/oldest", false, true)
  getFirstLastImages("compare_after", "/latest", false, false)
  handleTabOpen()
  clickOnEmbed()
  removeCurrentDateHighlight()
  if Evercam.Camera.is_public
    $(".div-embed-code").removeClass("hide")

  $('#calendar-before').datetimepicker
    format: 'm/d/Y H:m'
    id: 'before-calendar'
    onSelectTime: (dp, $input) ->
      $("#txtbefore").val($input.val())
      val = getQueryStringByName("after")
      url = "#{Evercam.request.rootpath}/compare?before=#{moment.utc($input.val()).toISOString()}"
      if val isnt null
        url = "#{url}&after=#{val}"
      if history.replaceState
        window.history.replaceState({}, '', url)
      getFirstLastImages("compare_before", "/#{(new Date($input.val())) / 1000}/nearest", true, false)
    onChangeMonth: (dp, $input) ->
      month = dp.getMonth() + 1
      year = dp.getFullYear()
      HighlightDaysInMonth("before-calendar", year, month)
      removeCurrentHourHighlight("before-calendar")
      showBeforeAfterLoadingAnimation("before-calendar")
    onSelectDate: (ct, $i) ->
      month = ct.getMonth() + 1
      year = ct.getFullYear()
      date = ct.getDate()
      HighlightSnapshotHour("before-calendar", year, month, date)
      HighlightDaysInMonth("before-calendar", year, month)
    onShow: (current_time, $input) ->
      month = current_time.getMonth() + 1
      year = current_time.getFullYear()
      removeCurrentHourHighlight("before-calendar")
      HighlightDaysInMonth("before-calendar", year, month)
      showBeforeAfterLoadingAnimation("before-calendar")

  $('#calendar-after').datetimepicker
    format: 'm/d/Y H:m'
    id: 'after-calendar'
    onSelectTime: (dp, $input) ->
      $("#txtafter").val($input.val())
      val = getQueryStringByName("before")
      url = "#{Evercam.request.rootpath}/compare"
      if val isnt null
        url = "#{url}?before=#{val}&after=#{moment.utc($input.val()).toISOString()}"
      else
        url = "#{url}?after=#{moment.utc($input.val()).toISOString()}"
      if history.replaceState
        window.history.replaceState({}, '', url)
      getFirstLastImages("compare_after", "/#{(new Date($input.val())) / 1000}/nearest", true, false)
    onChangeMonth: (dp, $input) ->
      month = dp.getMonth() + 1
      year = dp.getFullYear()
      removeCurrentHourHighlight("after-calendar")
      HighlightDaysInMonth("after-calendar", year, month)
      showBeforeAfterLoadingAnimation("after-calendar")
    onSelectDate: (ct, $i) ->
      month = ct.getMonth() + 1
      year = ct.getFullYear()
      date = ct.getDate()
      HighlightSnapshotHour("after-calendar", year, month, date)
      HighlightDaysInMonth("after-calendar", year, month)
    onShow: (current_time, $input) ->
      month = current_time.getMonth() + 1
      year = current_time.getFullYear()
      removeCurrentHourHighlight("after-calendar")
      HighlightDaysInMonth("after-calendar", year, month)
      showBeforeAfterLoadingAnimation("after-calendar")
