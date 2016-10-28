String::endsWith   ?= (s) -> s == '' or @slice(-s.length) == s

class app.videoCube
    @sideClasses =
        1: 'front'
        2: 'back'
        3: 'right'
        4: 'left'
        5: 'top'
        6: 'bottom'

    constructor: (config)->
        @options =
            width: '500px'
            parentSelectorForWidthScale: 'body'
            mouseDegreeBase: 90
            vimeoId: null
            holderSelector: null
            keyDegree: 10
            audioVolume: 0.7
            transitionTime: 600

        @options = $.extend @options, config
        @ratio = 56.25
        @initialX = 0
        @initialY = 0
        @currentX = -20
        @currentY = 45
        @tmpX = 0
        @tmpY = 0
        @moving = false

    init: ()->
        @$holder = $(@options.holderSelector)
        @$holder.addClass('cube-holder')
        @$cube = this.getCube()
        @$shadow = this.getCubeShadow()
        @$startVideo = this.getStartVideo()
        this.updateSizes()

    updateSizes: ()->
        size = this.calcWidth()
        @$holder.css
            width: size
            height: size
            marginLeft: -size/2
            marginTop: -size/2
            perspective: size*10
        startSize = Math.min(size*3, $(window).width())
        startW = this.getPossibleWidth(startSize, $(window).height())
        startH = startW * @ratio / 100

        @$startVideo.css
            width: startW
            height: startH
            marginLeft: -(startW - size) / 2
            marginTop: -(startH - size) / 2
        
        @$cube.find('.back').css 'transform', 
                                 "translateZ(#{-size/2}px) rotateY(180deg)"

        @$cube.find('.right').css 'transform',
                                  "rotateY(-270deg) translateX(#{size/2}px)"
        
        @$cube.find('.left').css 'transform',
                                 "rotateY(270deg) translateX(#{-size/2}px)"
        
        @$cube.find('.top').css 'transform',
                                "rotateX(90deg) translateY(#{-size/2}px)"

        @$cube.find('.bottom').css 'transform',
                                   "rotateX(270deg) translateY(#{size/2}px)"
        
        @$cube.find('.front').css 'transform',
                                  "translateZ(#{size/2}px)"

    calcWidth: ()->
        w = @options.width
        if w.endsWith('%')
            W = $(@options.parentSelectorForWidthScale).width()
            return W * parseInt(w) / 100
        return parseInt(w)

    getPossibleWidth: (w, h)->
        wanted_h = w * @ratio * 100
        while wanted_h > h
            w = w - 1
            wanted_h = (w * @ratio) / 100
        return w
    
    embed: ()->
        this.init()
        @$holder.append @$startVideo
        @$holder.append @$cube
        @$holder.append @$shadow
        this.buildPlayerAPIs()
        this.playAll()
        this.setListeners()

    setListeners: ()->
        self = this

        @$startVideo.click ->
            self.$holder.on 'mousedown', (e)->
                self.bindMouseMove(e)
            $('body').keydown (evt)->
                self.handleKey evt
            self.handleStartClick()

        
        @$holder.on "contextmenu", ->
            return false
        

        $(window).resize ->
            self.updateSizes()

        @$cube.find('.side').dblclick ->
            self.handleVolume $(this)

    bindMouseMove: (e)->
        e.preventDefault()
        self = this
        @initialX = e.pageX
        @initialY = e.pageY
        @tmpX = @currentX
        @tmpY = @currentY
        @moving = true;
        @$holder.on 'mousemove', (e)->
            self.handleMouseMove(e)
        $(document).on 'mouseup', ->
            self.unbindMouseMove()

    handleStartClick: ()->
        self = this
        @$startVideo.addClass('hidden')
        callback = -> 
            _callback = ->
                self.rotate(self.currentX, self.currentY)    
            self.$startVideo.hide()
            self.$cube.addClass('shown')
            self.$shadow.addClass('shown')
            window.setTimeout _callback, self.options.transitionTime    
        window.setTimeout callback, self.options.transitionTime

    handleMouseMove: (e)->
        if not @moving
            return
        xdeg = this.calcXDeg @initialY - e.pageY
        ydeg = this.calcYDeg e.pageX - @initialX
        @tmpX = @currentX + xdeg
        @tmpY = @currentY + ydeg
        this.rotate @tmpX, @tmpY


    handleKey: (evt)->
        ydeg = @currentY
        xdeg = @currentX
        code = evt.keyCode
        if not (code in [32, 37, 38, 39, 40])
            return
        if code == 32 # space -> reset
            ydeg = 0
            xdeg = 0
        else if code == 37 # left
            ydeg -= @options.keyDegree
        else if code == 38 # up
            xdeg += @options.keyDegree
            evt.preventDefault()
        else if code == 39 # right
            ydeg += @options.keyDegree
        else if code == 40 # down
            xdeg -= @options.keyDegree


        this.rotate xdeg, ydeg
        this.setCurrentXY xdeg, ydeg


    rotate: (x, y)->
        this.setShadow x, y
        @$cube.css 'transform', "rotateX(#{x}deg) rotateY(#{y}deg)"

    setShadow: (x, y)->
        y = y % 45
        width = 8 + (4*Math.abs(y)) / 45
        scale = 1 + (0.2*Math.abs(y)) / 45
        
        @$shadow.css
            transform: "scale(@{scale})"
            "box-shadow": "0 0 5em #{width}px";


    setCurrentXY: (x, y)->
        @currentX = x
        @currentY = y

    unbindMouseMove: ()->
        self = this
        @moving = false;
        this.setCurrentXY @tmpX, @tmpY
        @$holder.off 'mousemove'
        $(document).off 'mouseup'

    playAll: (duration)->
        self = this
        currentTime = 0
        if not duration
            @$cube.find('.front').data('player').getDuration().then (num)->
                self.playAll num
            return
        gapLength = duration / Object.keys(@constructor.sideClasses).length
        @$cube.find('.side').each ->
            player = $(this).data 'player'
            player.setCurrentTime currentTime
            player.setLoop true
            player.setVolume 0
            currentTime += gapLength
            player.play()


    muteAll: ()->
        self = this
        @$cube.find('.side').each ->
            player = $(this).data 'player'
            player.setVolume 0

    handleVolume: ($side)->
        this.muteAll()
        if not $side.data('unmuted')
            this.unmute $side
            $side.data('unmuted', true)
        else
            this.mute $side
            $side.data('unmuted', false)

    unmute: ($side)->
        $side.data('player').setVolume @options.audioVolume

    mute: ($side)->
        $side.data('player').setVolume 0

    calcXDeg: (length)->
        return ((length * @options.mouseDegreeBase) / 
                @$cube.width()) % @options.mouseDegreeBase

    calcYDeg: (length)->
        return ((length * @options.mouseDegreeBase) /
            @$cube.height()) % @options.mouseDegreeBase

    buildPlayerAPIs: ()->
        for num, className of @constructor.sideClasses
            $side = @$cube.find(".#{className}")
            $side.data 'player', new Vimeo.Player("iframe-#{className}")

    getCube: ()->
        cubeHTML = """
            <div class="cube">
            </div>
        """
        $cube =  $(cubeHTML)
        for num, className of @constructor.sideClasses
            url = "https://player.vimeo.com/video/#{@options.vimeoId}"
            sideHTML = """
                <div class="side #{className}">
                    <iframe id="iframe-#{className}"
                            src="#{url}?api=1&player_id=iframe-#{className}" 
                            width="640" 
                            height="360" 
                            frameborder="0" 
                            webkitallowfullscreen 
                            mozallowfullscreen 
                            allowfullscreen>
                    </iframe>
                </div>
            """
            $cube.append($(sideHTML))
        return $cube

    getStartVideo: ()->
        startVideoHTML = """
            <div class="start-video">
                <iframe src="https://player.vimeo.com/video/#{@options.vimeoId}" 
                        frameborder="0" 
                        webkitallowfullscreen 
                        mozallowfullscreen 
                        allowfullscreen>
                </iframe>
            </div>
        """
        return $(startVideoHTML)

    getCubeShadow: ()->
        shadowHTML = """
            <div class="shadow">
            </div>
        """
        return $(shadowHTML)