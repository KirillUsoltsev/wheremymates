class Gmap
  constructor: ->
    @my_marker_image = "http://img.brothersoft.com/icon/softimage/l/little_fighter_2-65984.jpeg"
    @marker_image = "http://img.brothersoft.com/icon/softimage/r/ruby-120627.jpeg"
    @map = @renderMap()
    @bounds = new google.maps.LatLngBounds()
    @me = window.current_user || {}
    @mates = if window.team_mates then window.team_mates else []
    @renderMates()
    @renderMe()
    @fitBounds()
    @detectUser() if window.request_geo

  renderMap: ->
    myOptions =
      minZoom: 2
      maxZoom: 18
      zoom: 6
      mapTypeId: google.maps.MapTypeId.TERRAIN
    new google.maps.Map document.getElementById("map_canvas"), myOptions

  fitBounds: ->
    @map.fitBounds(@bounds)

  renderMates: ->
    @renderMate(mate) for mate in @mates

  renderMate: (mate) ->
    if mate.id == @me.id
      @me.in_team = mate
    else if mate.latitude && mate.longitude
      geo = new google.maps.LatLng(mate.latitude, mate.longitude)
      mate.marker = new google.maps.Marker
        position: geo
        map: @map
        title: mate.name
        icon: @marker_image
      @bounds.extend(geo)
      @bindMate(mate)

  renderMe: ->
    if @me.latitude && @me.longitude
      geo = new google.maps.LatLng(@me.latitude, @me.longitude)
      if @me.marker
        @me.marker.setPosition(geo)
      else
        @me.marker = new google.maps.Marker
          position: geo
          map: @map
          title: @me.name
          icon: if @me.in_team then @my_marker_image else null
        if @me.in_team
          @me.in_team.marker = @me.marker
          @bindMate(@me.in_team)
      @bounds.extend(geo)

  detectUser: ->
    if navigator.geolocation
      navigator.geolocation.getCurrentPosition (position) =>
        @handleGeolocation(position)
      , => @handleNoGeolocation()
    else
      @handleNoGeolocation()

  handleGeolocation: (position)->
    @me.latitude = position.coords.latitude
    @me.longitude = position.coords.longitude
    pos = new google.maps.LatLng(@me.latitude, @me.longitude)
    new google.maps.InfoWindow
      map: @map
      position: pos
      content: 'You here!'
    $.post "/user/update_geo",
      user:
        latitude: position.coords.latitude
        longitude: position.coords.longitude
    @renderMe()
    @fitBounds()

  handleNoGeolocation: ->
    #@map.setCenter new google.maps.LatLng(-34.397, 150.644)
    false

  # ============ #

  bindMate: (mate) ->
    elem = $('.team_user[data-id=' + mate.id + ']')
    mate.elem = elem
    elem.data(mate: mate)
    elem.addClass('present')
    elem.click ->
      marker = mate.marker
      marker.setAnimation(google.maps.Animation.BOUNCE)
      setTimeout ->
        marker.setAnimation(null)
      , 700
    google.maps.event.addListener mate.marker, 'mouseover', ->
      elem.addClass('highlight')
    google.maps.event.addListener mate.marker, 'mouseout', ->
      elem.removeClass('highlight')


$ ->
  if $('#map_canvas').length > 0 && google?
    new Gmap
