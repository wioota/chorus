chorus.pages.Bare = chorus.views.Bare.extend({
    bindCallbacks: function() {
        if (chorus.user) this.bindings.add(chorus.user, "change", this.render);
    },

    dependentResourceNotFound: function() {
        chorus.pageOptions = this.failurePageOptions();
        Backbone.history.loadUrl("/invalidRoute");
    },

    dependentResourceForbidden: function(model) {
        chorus.pageOptions = this.failurePageOptions();

        var error = model.serverErrors;
        if(error && error.type) {
            Backbone.history.loadUrl("/forbidden");
            return;
        }

        Backbone.history.loadUrl("/unauthorized");
    },

    unprocessableEntity: function(model) {
        var errors = model.serverErrors;
        if (errors) {
            var undefinedErrorTitle = "unprocessable_entity.unidentified_error.title";
            if(errors.record) {
                var code = "record_error." + errors.record;
                var title = I18n.lookup(code + "_title");
                chorus.pageOptions = {
                    title: title ? title : t(undefinedErrorTitle),
                    text: t(code, errors)
                };
            } else {
                chorus.pageOptions = {
                    title: t(undefinedErrorTitle),
                    text: errors.message
                };
            }
        }

        Backbone.history.loadUrl("/unprocessableEntity");
    },

    dependOn: function(model, functionToCallWhenLoaded) {
        this.bindings.add(model, "resourceNotFound", this.dependentResourceNotFound);
        this.bindings.add(model, "resourceForbidden", _.bind(this.dependentResourceForbidden, this, model));
        this.bindings.add(model, "unprocessableEntity", _.bind(this.unprocessableEntity, this, model));
        this.bindings.add(model, "change", this.render);
        if (functionToCallWhenLoaded) {
            if (
                model.loaded) {
                functionToCallWhenLoaded.apply(this);
            } else {
                this.bindings.add(model, "loaded", functionToCallWhenLoaded);
            }
        }
    },

    failurePageOptions: function() {}
});

chorus.pages.Base = chorus.pages.Bare.extend({
    constructorName: "Page",
    templateName: "logged_in_layout",

    subviews: {
        "#header": "header",
        "#main_content": "mainContent",
        "#breadcrumbs": "breadcrumbs",
        "#sidebar .multiple_selection": "multiSelectSidebarMenu",
        "#sidebar .sidebar_content.primary": "sidebar",
        "#sidebar .sidebar_content.secondary": "secondarySidebar",
        "#sub_nav": "subNav"
    },

    setupSubviews: function() {
        this.header = this.header || new chorus.views.Header({ workspaceId: this.workspaceId });
        this.breadcrumbs = new chorus.views.BreadcrumbsView({
            breadcrumbs: _.isFunction(this.crumbs) ? this.crumbs() : this.crumbs
        });
    },

    showHelp: function(e) {
        e.preventDefault();
        chorus.help();
    }
});
