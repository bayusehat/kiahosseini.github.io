class app.videoPlayer
    constructor: (config)->
        @options =
            vimeoId: null
            holderSelector: null
            minWidth: 800
            minHeight: 600

        @options = $.extend @options, config
        @ratio = 56.25 # (9 / 16) * 100
    
    init: ()->
        @$holder = $(@options.holderSelector)
        @$holder.addClass('video-container')
        @$iframe = this.getIframe()

    embed: ()->
        this.init()
        @$holder.append @$iframe
        this.setListeners()
        this.handleResize()

    setListeners: ()->
        self = this
        $(window).resize ->
            self.handleResize()

        @$holder.resize ->
            self.handleResize()
        

    getIframe: ()->
        $iframe =  $('<iframe frameborder="0"
                              webkitallowfullscreen
                              mozallowfullscreen
                              allowfullscreen>
                      </iframe>')
        $iframe.attr 'src', 
                     "https://player.vimeo.com/video/#{@options.vimeoId}"
        return $iframe

    handleResize: ()->
        W = $(window).width()
        H = $(window).height()

        w = Math.max(W, @options.minWidth)
                          
        h = this.calcHeight(Math.max(@options.minHeight, this.calcHeight(w)))
        console.log w, W, h, H
        while h < H or w < W
            w += 1
            h = this.calcHeight(w)
        h = this.calcHeight(w)
        this.setSize(w, h)
        if w > @options.minWidth and h > @options.minHeight
            this.reposition(w, h, W, H)
    
    calcHeight: (w)->
        return (w * @ratio)/100

    getPossibleWidth: (w, h)->
        wanted_h = w * @ratio * 100
        while wanted_h > h
            w = w - 1
            wanted_h = (w * @ratio) / 100
        return w

    reposition: (w, h, W, H)->
        @$holder.css
            'margin-top': (H - h) / 2
            'margin-left': (W - w) / 2

    setSize: (w, h)->
        @$holder.width(w)
        @$holder.height(h)

