showError = (message) ->
  Notification.show(message)
  true

showFeedback = (message) ->
  Notification.show(message)
  true

onAddShareClicked = (event) ->
  event.preventDefault()
  link=$(event.target)
  emailAddress = link.attr("email")
  cameraID = link.attr("camera_id")
  permissions = "minimal"
  onError = (jqXHR, status, error) ->
    showError("Add camera to my shared cameras failed.")
    false
  onSuccess = (data, status, jqXHR) ->
    if data.success
      showFeedback("Successfully added to your shared cameras.")
    else
      showError("Failed to add camera to your shared cameras.")
    true
  window.Evercam.Share.createShare(cameraID, emailAddress, permissions, onSuccess, onError)
  true

initialize = ->
  $(".create-share-button").click(onAddShareClicked)
  true


if !window.Evercam
  window.Evercam = {}

window.Evercam.Publiccam =
  initialize: initialize



