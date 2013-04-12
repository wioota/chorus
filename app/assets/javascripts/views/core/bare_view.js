chorus.views.Bare = Backbone.View.include(
        chorus.Mixins.Events
    ).extend({
        constructorName: "View",

        //The order in which setup methods are called on views is as follows:
        // - _configure
        // - _ensureElement
        // - initialize
        // -> preInitialize
        // -> -> makeModel
        // -> _initializeHeaderAndBreadcrumbs
        // -> setup
        // -> bindCallbacks
        // -> bindHotKeys
        // - delegateEvents
        preInitialize: function() {
            this.makeModel.apply(this, arguments);
            this.resource = this.model || this.collection;
        },

        initialize: function initialize() {
            this.preInitialize.apply(this, arguments);
            chorus.viewsToTearDown.push(this);
            this.subViewObjects = [];
            this.subscriptions = [];

            this._initializeHeaderAndBreadcrumbs();
            this.setup.apply(this, arguments);

            this.bindCallbacks();
            this.bindHotkeys();

            if (this.requiredResources.length !== 0 && this.requiredResources.allResponded()) {
                this.resourcesLoaded();
            }
        },

        _initializeHeaderAndBreadcrumbs: $.noop,
        makeModel: $.noop,
        setup: $.noop,
        postRender: $.noop,
        bindCallbacks: $.noop,
        preRender: $.noop,
        setupSubviews: $.noop,
        resourcesLoaded: $.noop,
        displayLoadingSection: $.noop,

        //Subviews that don't require any configuration should be included in the subviews hash.
        //Subviews can also be manually added (for example within callbacks) using this.registerSubView(view)
        // in the parent view after creating the new view
        //
        //See wiki
        registerSubView: function(view) {
            if (_.indexOf(this.subViewObjects, view) === -1) {
                this.subViewObjects.push(view);
                chorus.unregisterView(view);

                view.parentView = this;
            }
        },

        getSubViews: function() {
            return this.subViewObjects;
        },

        torndown: false,

        // Remove a view from the dom, unbind any events, and hopefully remove it from memory.
        teardown: function(preserveContainer) {
            this.torndown = true;

            chorus.unregisterView(this);
            this.unbind();
            this.stopListening();
            this.undelegateEvents();
            this.requiredResources.cleanUp(this);
            this.$el.unbind();
            if(preserveContainer) {
                $(this.el).children().remove();
                $(this.el).html("");
            } else {
                $(this.el).remove();
            }

            this.scrollHandle && chorus.PageEvents.unsubscribe(this.scrollHandle);

            while(!_.isEmpty(this.subViewObjects)) {
                var subViewObject = this.subViewObjects.pop();
                subViewObject.teardown();
            }

            _.each(this.subscriptions, function(handle) {
                chorus.PageEvents.unsubscribe(handle);
            });
            this.subscriptions = [];

            if(this.parentView) {
                var subViewObjects = this.parentView.subViewObjects;
                var index = subViewObjects.indexOf(this);
                if(index > -1) subViewObjects.splice(index, 1);
                delete this.parentView;
            }
        },

        bindHotkeys: function() {
            var keydownEventName = "keydown." + this.cid;
            _.each(this.hotkeys, _.bind(function(eventName, hotkey) {
                $(document).bind(keydownEventName, chorus.hotKeyMeta + '+' + hotkey, function(event) {
                    chorus.PageEvents.broadcast(eventName, event);
                });
            }));

            if (this.hotkeys) {
                chorus.afterNavigate(function() {
                    $(document).unbind(keydownEventName);
                });
            }
        },

        context: {},
        subviews: {},

        //Sets backbone view options and creates a listener for completion of requiredResources
        _configure: function(options) {
            var backboneOptions = [{}];
            if (arguments.length > 0 && _.isObject(arguments[0])) {
                backboneOptions = [arguments[0]];
            }
            this._super('_configure', backboneOptions);

            this.requiredResources = new chorus.RequiredResources();

            this.listenTo(this.requiredResources, 'allResourcesResponded', function() {
                this.resourcesLoaded();
                this.render();
            });

            this.requiredResources.reset(options.requiredResources);
        },

        //Creates a modal of a given type and launches it.
        createModal: function(e, modalType) {
            e.preventDefault();
            var button = $(e.target).closest("button, a");
            var modalClass = chorus[modalType + 's'][button.data(modalType)];
            var options = _.extend(button.data(), { pageModel: this.model, pageCollection: this.collection });
            var modal = new modalClass(options);
            modal.launchModal();
        },

        createDialog: function(e) {
            this.createModal(e, "dialog");
        },

        createAlert: function(e) {
            this.createModal(e, "alert");
        },

        //Render the view and all subviews, if all requiredResources have responded from the server
        //Calls pre/postRender
        render: function render() {
            this.preRender();

            var evaluatedContext = {};
            if (!this.displayLoadingSection()) {
                if (!this.requiredResources.allResponded()) {
                    return this;
                }
                // The only template rendered when loading section is displayed is the loading section itself, so no context is needed.
                evaluatedContext = _.isFunction(this.context) ? this.context() : this.context;
            }

            $(this.el).html(this.template(evaluatedContext))
                .addClass(this.className || "")
                .addClass(this.additionalClass || "")
                .attr("data-template", this.templateName);
            this.renderSubviews();
            this.postRender($(this.el));
            this.renderHelps();
            chorus.PageEvents.broadcast("content:changed");
            return this;
        },

        renderSubviews: function() {
            this.setupSubviews();
            var subviews;
            if (this.displayLoadingSection()) {
                subviews = {".loading_section": "makeLoadingSectionView"};
            } else {
                subviews = this.subviews;
            }

            _.each(subviews, function(property, selector) {
                var subview = this.getSubview(property);
                if(subview) this.registerSubView(subview);
                this.renderSubview(property, selector);
            }, this);
        },

        renderSubview: function(property, selector) {
            var view = this.getSubview(property);
            if (view) {
                if (!selector) {
                    _.each(this.subviews, function(value, key) {
                        if (value === property) {
                            selector = key;
                        }
                    });
                }
                var element = this.$(selector);
                if (element.length) {
                    if (element[0] !== view.el) {
                        var id = element.attr("id"), klass = element.attr("class");
                        $(view.el).attr("id", id);
                        $(view.el).addClass(klass);
                        element.replaceWith(view.el);
                    }

                    if (!view.requiredResources || view.requiredResources.allResponded()) {
                        view.render();
                    }
                    view.delegateEvents();
                }
            }
        },

        getSubview: function(property) {
            return _.isFunction(this[property]) ? this[property]() : this[property];
        },

        renderHelps: function() {
            var classes;
            var helpElements = this.$(".help");
            if (helpElements.length) {
                if ($(this.el).closest(".dialog").length) {
                    classes = "tooltip-help tooltip-modal";
                } else {
                    classes = "tooltip-help";
                }
            }
            _.each(helpElements, function(element) {
                $(element).qtip({
                    content: $(element).data("text"),
                    show: 'mouseover',
                    hide: {
                        delay: 1000,
                        fixed: true,
                        event: 'mouseout'
                    },
                    position: {
                        viewport: $(window),
                        my: "bottom center",
                        at: "top center"
                    },
                    style: {
                        classes: classes,
                        tip: {
                            width: 20,
                            height: 13
                        }
                    }
                });
            });
        },

        subscribePageEvent: function(eventName, callback, context, id) {
            context = context || this;
            if(!id && _.isString(context)) {
                id = context;
                context = this;
            }
            var subscription = chorus.PageEvents.subscribe(eventName, callback, context, id);
            this.subscriptions.push(subscription);
        },

        template: function template(context) {
            if (this.displayLoadingSection()) {
                return '<div class="loading_section"/>';
            } else {
                return Handlebars.helpers.renderTemplate(this.templateName, context).toString();
            }
        },

        makeLoadingSectionView: function() {
            var opts = _.extend({}, this.loadingSectionOptions());
            return new chorus.views.LoadingSection(opts);
        },

        loadingSectionOptions: function() {
            return { delay: 125 };
        },

        setupScrolling: function(selector, options) {
            _.defer(_.bind(function() {
                if(this.torndown) { return; }
                var $el = this.$(selector);
                if (!$el.length) {
                    $el = $(selector);
                }

                if ($el.length > 0) {
                    var alreadyInitialized = $el.data("jsp");

                    $el.jScrollPane(options);
                    $el.find('.jspVerticalBar').hide();
                    $el.find('.jspHorizontalBar').hide();

                    // TODO #42333397: clean up this binding at teardown because it leaks memory
                    $el.bind("jsp-scroll-y", _.bind(function() { this.trigger("scroll"); }, this));

                    if(this.scrollHandle) {
                        chorus.PageEvents.unsubscribe(this.scrollHandle);
                        var index = this.subscriptions.indexOf(this.scrollHandle);
                        if(index > -1) this.subscriptions.splice(index, 1);
                    }
                    this.scrollHandle = this.subscribePageEvent("content:changed", function() { this.recalculateScrolling($el); });
                    this.subscriptions.push(this.scrollHandle);

                    if (!alreadyInitialized) {
                        $el.addClass("custom_scroll");
                        $el.unbind('hover').hover(function() {
                            $el.find('.jspVerticalBar, .jspHorizontalBar').fadeIn(150);
                        }, function() {
                            $el.find('.jspVerticalBar, .jspHorizontalBar').fadeOut(150);
                        });

                        $el.find('.jspContainer').unbind('mousewheel', this.onMouseWheel).bind('mousewheel', this.onMouseWheel);

                        if (chorus.page && chorus.page.bind) {
                            if(this.resizeCallback) {
                                this.stopListening(chorus.page, "resized", this.resizeCallback);
                            }
                            this.resizeCallback = function() { this.recalculateScrolling($el); };
                            this.listenTo(chorus.page, "resized", this.resizeCallback);
                        }
                    }
                }
            }, this));
        },

        onMouseWheel: function(event) {
            event.preventDefault();
        },

        recalculateScrolling: function(el) {
            var elements = el ? [el] : this.$(".custom_scroll");
            _.each(elements, function(el) {
                el = $(el);
                var api = el.data("jsp");
                if (api) {
                    _.defer(_.bind(function() {
                        api.reinitialise();
                        if (!api.getIsScrollableH() && api.getContentPositionX() > 0) {
                            el.find(".jspPane").css("left", 0);
                        }
                        if (!api.getIsScrollableV() && api.getContentPositionY() > 0) {
                            el.find(".jspPane").css("top", 0);
                        }
                        el.find('.jspVerticalBar').hide();
                        el.find('.jspHorizontalBar').hide();
                    }, this));
                }
            });
        },

        onceLoaded: function(subject, callback) {
            if (subject.loaded) {
                callback.apply(this);
            } else {
                subject.once('loaded', _.bind(callback, this));
            }
        }
    }, {
        extended: function(subclass) {
            var proto = subclass.prototype;
            if (proto.templateName) {
                proto.className = proto.templateName.replace(/\//g, "_");
            }

            _.defaults(proto.events, this.prototype.events);
        }
    });

chorus.views.Bare.extend = chorus.classExtend;
