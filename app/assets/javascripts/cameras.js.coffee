window.showFeedback = (message) ->
  Notification.show(message)

refreshThumbnails = ->
  $('.camera-thumbnail').each ->
    img = $(this)
    img_url = img.attr "data-proxy"
    if img_url.endsWith "thumbnail"
      src = "#{img_url}?rand=" + new Date().getTime()
    else
      src = "#{img_url}&rand=" + new Date().getTime()
    img.attr "src", src
  setTimeout refreshThumbnails, 60000

hideThumbnailGif = ->
  $('.refresh-camera-thumbnail').on "click", ->
    gifid = $(this)
    camera_id = gifid.attr 'id'
    control_id = '#' + camera_id
    $("#{control_id} > .fa-still").css 'display', 'none'
    $("#{control_id} > .refresh-gif-thumbnail").css 'display', 'block'
    refreshCameraStatus(camera_id, control_id)

hide_gif = (control_id) ->
  $("#{control_id} .fa-still").css 'display', 'block'
  $("#{control_id} .refresh-gif-thumbnail").css 'display', 'none'

refreshCameraStatus = (cam_id, contr_id) ->
  NProgress.start()
  data = {}

  camera_id = cam_id
  control_id = contr_id

  onError = (jqXHR, status, error) ->
    hide_gif(control_id)
    NProgress.done()

  onSuccess = (data, status, jqXHR) ->
    hide_gif(control_id)
    $("#{control_id}").hide()
    NProgress.done()

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/x-www-form-urlencoded"
    type: 'POST'
    url: "#{Evercam.API_URL}cameras/#{camera_id}/recordings/snapshots?api_id=#{Evercam.User.api_id}&api_key=#{Evercam.User.api_key}"

  sendAJAXRequest(settings)

initNotification = ->
  Notification.init(".bb-alert");
  if notifyMessage
    Notification.show notifyMessage

setLayoutOnCamerasCount = ->
  if $('#index-camera-count').val() < 3
    $('#camera-index .camera-index').removeClass('col-lg-4').addClass('col-lg-6 camera-index-height')
  else
    $('#camera-index .camera-index').removeClass('col-lg-6 camera-index-height').addClass('col-lg-4')

window.initializeCameraIndex = ->
  Metronic.init()
  Layout.init()
  QuickSidebar.init()
  initNotification()
  refreshThumbnails()
  hideThumbnailGif()
  $('[data-toggle="tooltip"]').tooltip()
  NProgress.done()
  setLayoutOnCamerasCount()
