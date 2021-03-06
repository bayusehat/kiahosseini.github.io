// Generated by CoffeeScript 1.9.3
(function() {
  app.videoPlayer = (function() {
    function videoPlayer(config) {
      this.options = {
        vimeoId: null,
        holderSelector: null,
        minWidth: 800,
        minHeight: 600
      };
      this.options = $.extend(this.options, config);
      this.ratio = 56.25;
    }

    videoPlayer.prototype.init = function() {
      this.$holder = $(this.options.holderSelector);
      this.$holder.addClass('video-container');
      return this.$iframe = this.getIframe();
    };

    videoPlayer.prototype.embed = function() {
      this.init();
      this.$holder.append(this.$iframe);
      this.setListeners();
      return this.handleResize();
    };

    videoPlayer.prototype.setListeners = function() {
      var self;
      self = this;
      $(window).resize(function() {
        return self.handleResize();
      });
      return this.$holder.resize(function() {
        return self.handleResize();
      });
    };

    videoPlayer.prototype.getIframe = function() {
      var $iframe;
      $iframe = $('<iframe frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen> </iframe>');
      $iframe.attr('src', "https://player.vimeo.com/video/" + this.options.vimeoId);
      return $iframe;
    };

    videoPlayer.prototype.handleResize = function() {
      var H, W, h, w;
      W = $(window).width();
      H = $(window).height();
      w = Math.max(W, this.options.minWidth);
      h = this.calcHeight(Math.max(this.options.minHeight, this.calcHeight(w)));
      console.log(w, W, h, H);
      while (h < H || w < W) {
        w += 1;
        h = this.calcHeight(w);
      }
      h = this.calcHeight(w);
      this.setSize(w, h);
      if (w > this.options.minWidth && h > this.options.minHeight) {
        return this.reposition(w, h, W, H);
      }
    };

    videoPlayer.prototype.calcHeight = function(w) {
      return (w * this.ratio) / 100;
    };

    videoPlayer.prototype.getPossibleWidth = function(w, h) {
      var wanted_h;
      wanted_h = w * this.ratio * 100;
      while (wanted_h > h) {
        w = w - 1;
        wanted_h = (w * this.ratio) / 100;
      }
      return w;
    };

    videoPlayer.prototype.reposition = function(w, h, W, H) {
      return this.$holder.css({
        'margin-top': (H - h) / 2,
        'margin-left': (W - w) / 2
      });
    };

    videoPlayer.prototype.setSize = function(w, h) {
      this.$holder.width(w);
      return this.$holder.height(h);
    };

    return videoPlayer;

  })();

}).call(this);
