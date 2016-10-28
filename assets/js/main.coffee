---
---
class Kia.Base

  constructor: ->
    @isDesktop = true
    @isTablet = false
    @isPhone = false
    @elements =
      $content: $(".content-wrapper .content")
      $contentWrapper: $(".content-wrapper")
      $left: $(".left-wrapper")
      $right: $(".right-wrapper")
    this.setListeners()
    this.initPanels()
    this.syncSizes()

  initPanels: ->
    if $.cookie("hide-left")
      this.hideLeft()
    if $.cookie("hide-right")
      this.hideRight()

  toggleLeft: ->
    if @elements.$left.hasClass('open')
      this.hideLeft()
    else
      this.showLeft()

  showLeft: ->
    $.removeCookie("hide-left", {path: '/'})
    if not @isDesktop
      this.hideRight()
    @elements.$left.addClass('open')
    @elements.$contentWrapper.addClass('left-open')

  hideLeft: ->
    $.cookie("hide-left", 1, {path: '/'})
    @elements.$left.removeClass('open')
    @elements.$contentWrapper.removeClass('left-open')

  toggleRight: ->
    if @elements.$right.hasClass('open')
      this.hideRight()
    else
      this.showRight()

  showRight: ->
    $.removeCookie("hide-right", {path: '/'})
    if not @isDesktop
      this.hideLeft()
    @elements.$right.addClass('open')
    @elements.$contentWrapper.addClass('right-open')

  hideRight: ->
    $.cookie("hide-right", 1, {path: '/'})
    @elements.$right.removeClass('open')
    @elements.$contentWrapper.removeClass('right-open')

  buildGists: ->
    self = this
    $('span[data-gist-id]').each (i, v)->
      gistId = $(v).attr('data-gist-id')
      url = """
        https://gist.github.com/kiahosseini/#{gistId}.json?callback=?
        """
      $.getJSON url, (data)->
        self.loadGist($(v), data)

  loadGist: (container, data) ->
    self = this
    container.replaceWith $(data.div)
    self.addStylesheetOnce data.stylesheet

  addStylesheetOnce: (url) ->
    $head = $('head')
    if $head.find('link[rel="stylesheet"][href="' + url + '"]').length < 1
      $head.append "<link rel=\"stylesheet\" href=\"#{url}\" type=\"text/css\" />"

  setCurrentLink: ->
    $('a[href="' + window.location.pathname + '"]').addClass('active').parents('li').find('>a').addClass('active')

  setListeners: ->
    self = this
    this.setMenuListeners()
    $(window).resize ->
      self.windowResize()

  setMenuListeners: ->
    $('.menu li.parent').click (e)->
      $(this).toggleClass('open')
      e.stopPropagation()
    $(document).click ->
      $('.menu li.parent').removeClass('open')

  windowResize: ->
    this.syncSizes()
    this.updateScrollBar()

  syncSizes: ->
    w = $(window).width()
    if w < 1025
      @isDesktop = false
      if @elements.$left.hasClass('open') and 
         @elements.$right.hasClass('open')
        this.hideRight()
      if w > 800
        @isTablet = true
        @isPhone = false
      else
        @isPhone = true
        @isTablet = false
    else
      @isDesktop = true
      @isTablet = false
      @isPhone = false
  
  updateScrollBar: ->
    @elements.$content.perfectScrollbar('updateScrollBar')