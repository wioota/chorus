chorus.Mixins.StickyHeader = {
    bindStickyHeader: function() {
        if(!this.boundScrollHandler) {
            this.boundScrollHandler = _.bind(this.scrollHandler, this);
            $(window).scroll(this.boundScrollHandler);
        }
    },

    stickyHeaderElements: function() { return [this.$el]; },

    scrollHandler: function() {
        if (!this.$el) return;
        this.topPosition = this.topPosition || this.$el.offset().top;
        var distanceToTop = this.topPosition  - $(window).scrollTop();
        var distanceToHeader = distanceToTop - $(".header").outerHeight();
        this.contentDetailsAtTop = distanceToHeader <= 0;

        _.each(this.stickyHeaderElements(), _.bind(this.makeSpacerForElement, this));
    },

    makeSpacerForElement: function (elem, index) {
        var spacerClass = "scroll_spacer";
        var spacerClassToAvoidSpacerDups = spacerClass + index;

        elem = this.extractElementFromSelectionArrays(elem, spacerClass);

        if(this.contentDetailsAtTop) {
            if ($("."+spacerClassToAvoidSpacerDups).length === 0) {

                var $spacer = elem.clone();
                $spacer.addClass(spacerClass);
                $spacer.addClass(spacerClassToAvoidSpacerDups);
                $spacer.css("visibility", "hidden");
                elem.before($spacer);
            }
        } else {
            $("."+spacerClass).remove();
        }

        if(!elem.hasClass(spacerClass)) { elem.toggleClass('fixed_header', this.contentDetailsAtTop); }
    },

    teardownStickyHeaders: function() {
        $(window).unbind('scroll', this.boundScrollHandler);
        delete this.boundScrollHandler;
    },

    extractElementFromSelectionArrays: function (elem, spacerClass) {
        if (elem.length > 1) {
            elem = $(_.detect(elem, function (el) {
                return !($(el).hasClass(spacerClass));
            }));
        }
        return elem;
    }
};