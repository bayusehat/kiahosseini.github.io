class app.mobilePlayer
    constructor: (config)->
        @options =
            holderSelector: null
            deviceMaxDegree: 45
            audioVolume: 0.5
            sources: []
            controlsHeight: 50

        @options = $.extend @options, config
        @ratio = 56.25
        @muted = false    
        @loop = true
        @audioVolumeInitial = @options.audioVolume

    init: ()->
        @$holder = $(@options.holderSelector)
        @$holder.addClass('player-holder')
        @$player = this.getPlayer()
        @video = @$player.get(0)
        @$video = $(@$player.get(0))
        @$play = @$player.find('.play')
        @$pause = @$player.find('.pause')
        @$loop = @$player.find('.loop')
        @$progress = @$player.find('.progress')
        @$loadedBar = @$player.find('.loaded-bar')
        @$currentTimeBar = @$player.find('.current-time-bar')
        @$time = @$player.find('.time')
        @$volumeUp = @$player.find('.volume-up')
        @$volumeDown = @$player.find('.volume-down')
        @$volumeLabel = @$player.find('.volume-label')
        @$fullscreen = @$player.find('.fullscreen')
        this.setVolume(@options.audioVolume)
        
        @$pause.hide()
    
    embed: ()->
        this.init()
        @$holder.append @$player
        this.setListeners()
        this.handleResize()

    setListeners: ()->
        self = this
        
        $(window).resize ->
            self.handleResize()

        @$play.click ->
            self.play()

        @$pause.click ->
            self.pause()

        @$loop.click ->
            self.handleLoopClick()

        @$fullscreen.click ->
            self.handleFullscreenClick()

        @$volumeUp.click ->
            self.volumeUp()

        @$volumeDown.click ->
            self.volumeDown()

        @$volumeLabel.click ->
            self.handleVolumeLabel()

        if window.DeviceOrientationEvent
            window.addEventListener 'deviceorientation', (evt)->
                self.handleDeviceOrientation(evt)

        @video.addEventListener 'progress', ->
            self.handleProgress()
        
        @video.addEventListener 'timeupdate', ->
            self.handleTimeUpdate()

        @video.addEventListener 'ended', ->
            self.handleEnded()

        @$progress.click (evt)->
            self.handleProgressClick(evt)

        $(document).on 'keyup', (evt)->
            self.handleEscapeKey(evt)


    play: ()->
        @video.play()
        this.updateTime()
        @$play.hide()
        @$pause.show()

    pause: ()->
        @video.pause()
        @$pause.hide()
        @$play.show()

    mute: ()->
        @video.muted = true
        this.setVolume(0)

    unmute: ()->
        @video.muted = true
        this.setVolume(@audioVolumeInitial)

    handleLoopClick: ()->
        if @loop
            @loop = false
            @video.loop = false
            @$loop.addClass('disabled')
        else
            @loop = true
            @video.loop = true
            @$loop.removeClass('disabled')
    
    handleEscapeKey: (evt)->
        if @fullscreen and evt.keyCode == 27 # Escape keyCode
            this.disableFullscreen()

    handleFullscreenClick: ()->
        if @fullscreen
            this.disableFullscreen()
        else
            this.enableFullscreen()

    enableFullscreen: ()->
        elem = document.documentElement
        method = this.getFullScreenMethod(elem)
        
        if not method.request
            return
        @fullscreen = true
        @$fullscreen.addClass('disabled')
        method.request.call(elem)
    
    disableFullscreen: ()->
        elem = document.documentElement
        method = this.getFullScreenMethod(elem)
        method.cancel.call(document)
        @fullscreen = false
        @$fullscreen.removeClass('disabled')


    getFullScreenMethod: (elem)->
        method = 
            request: elem.requestFullScreen or elem.webkitRequestFullScreen or elem.mozRequestFullScreen
            cancel: document.exitFullscreen or document.webkitExitFullscreen or document.mozCancelFullScreen

    handleVolumeLabel: ()->
        if @muted
            @muted = false
            this.unmute()
        else
            @muted = true
            this.mute()

    volumeUp: ()->
        this.setVolume(@options.audioVolume + 0.1)
    
    volumeDown: ()->
        this.setVolume(@options.audioVolume - 0.1)

    setVolume: (v)->
        v = Math.min(Math.max(v, 0), 1)
        @video.volume = v
        @options.audioVolume = v
        if 0.0 < v < 0.1
            v = 0
        else if 0.9 < v < 1
            v = 1
        @$volumeLabel.find('i').hide()
        v = (v * 10).toFixed(0)
        if parseInt(v) == 0
            @video.muted = true
            @muted = true
            @$volumeLabel.find('i.icon-volume-mute').show()
            return
        else if 0 < v < 5
            @$volumeLabel.find('i.icon-volume-low').show()
        else if 5 <= v < 8
            @$volumeLabel.find('i.icon-volume-medium').show()

        else if v >= 8
            @$volumeLabel.find('i.icon-volume-high').show()
        @video.muted = false
        @muted = false 

    handleDeviceOrientation: (evt)->
        this.changeOrientation evt.beta * -1, evt.gamma

    changeOrientation: (xdeg, ydeg)->
        xdeg = Math.min(Math.max(xdeg, -@options.deviceMaxDegree), 
                        @options.deviceMaxDegree)
        
        ydeg = Math.min(Math.max(ydeg, -@options.deviceMaxDegree), 
                        @options.deviceMaxDegree)

        if $(window).height() > $(window).width()
            @$video.css 'transform', "rotateX(#{xdeg}deg) rotateY(#{ydeg}deg)"
        else
            @$video.css 'transform', "rotateX(#{ydeg}deg) rotateY(#{xdeg}deg)"

    handleProgressClick: (evt)->
        xl = @$progress.get(0).getBoundingClientRect().left
        xr = xl + @$progress.get(0).getBoundingClientRect().width
        length = xr - xl
        x = evt.pageX - xl
        @video.currentTime = (x * @video.duration) / length

    handleProgress: ()->
        if not @video.buffered.length
            return true
        @$loadedBar.css
            left: 0
            right: "#{Math.floor(100 - (100 * 
                        (@video.buffered.end(0))/@video.duration))}%"

    handleTimeUpdate: ()->
        duration = @video.duration
        currentTime = @video.currentTime
        
        @$currentTimeBar.css 
            left: 0
            right: "#{Math.floor(100 - ((currentTime / duration) * 100))}%"
        
        this.updateTime()
    
    handleEnded: ()->
        @$pause.hide()
        @$play.show()

    updateTime: ()->
        @$time.text """
                    #{this.msToTime(@video.currentTime*1000)}/
                    #{this.msToTime(@video.duration*1000)}
                """
        

    getPlayer: ()->
        playerHTML = """
            <video loop">
            </video>
            <div class="controls">
                <button class="play" title="Play">
                    <i class="icon icon-play3"></i>
                </button>
                <button class="pause" title="Pause">
                    <i class="icon icon-pause2"></i>
                </button>
                <button class="loop" title="Loop">
                    <i class="icon icon-loop"></i>
                </button>
                <div class="progress-holder">
                    <div class="progress">
                        <div class="bar current-time-bar">
                        </div>
                        <div class="bar loaded-bar">
                        </div>
                    </div>
                    <div class="time">
                        00:00
                    </div>
                </div>
                <button class="volume-down" title="Volume Down">
                    <i class="icon icon-volume-decrease"></i>
                </button>
                <button class="volume-up" title="Volume Up">
                    <i class="icon icon-volume-increase"></i>
                </button>
                <button class="volume-label" title="Volume">
                    <i class="icon icon-volume-high"></i>
                    <i class="icon icon-volume-medium"></i>
                    <i class="icon icon-volume-low"></i>
                    <i class="icon icon-volume-mute"></i>
                    <i class="icon icon-volume-mute2"></i>
                </button>
                <button class="fullscreen" title="Fullscreen">
                    <i class="icon icon-enlarge"></i>
                </button>
            </div>
        """
        $player = $(playerHTML)
        for source in @options.sources
            $($player.get(0)).append """
                <source src="#{source.src}" type="#{source.type}" />
            """
        return $player

    handleResize: ()->
        W = $(window).width()
        H = $(window).height() - @options.controlsHeight

        w = this.getPossibleWidth W, H
        this.setSize(w, ((w * @ratio) / 100) + @options.controlsHeight)

        this.reposition()
    
    getPossibleWidth: (w, h)->
        wanted_h = (w * @ratio * 100)
        while wanted_h > h
            w = w - 1
            wanted_h = (w * @ratio) / 100
        return w

    reposition: ()->
        margin_top = ($(window).height() - @$holder.height()) / 2
        if margin_top < 0 then margin_top = 0 
        @$holder.css('margin-top', margin_top)

    setSize: (w, h)->
        @$holder.width(w)
        @$holder.height(h)

    msToTime: (duration)->
        milliseconds = parseInt((duration%1000)/100)
        seconds = parseInt((duration/1000)%60)
        minutes = parseInt((duration/(1000*60))%60)
        hours = parseInt((duration/(1000*60*60))%24);

        hours = if hours < 10 then "0" + hours else hours
        minutes = if minutes < 10 then "0" + minutes else minutes
        seconds = if seconds < 10 then "0" + seconds else seconds;

        if hours is not '00'
            return "#{hours}:#{minutes}:#{seconds}"
        else
            return "#{minutes}:#{seconds}"
