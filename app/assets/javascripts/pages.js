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

    handleFetchErrorsFor: function(resource) {
        this.bindings.add(resource, "resourceNotFound", this.dependentResourceNotFound);
        this.bindings.add(resource, "resourceForbidden", _.bind(this.dependentResourceForbidden, this, resource));
        this.bindings.add(resource, "unprocessableEntity", _.bind(this.unprocessableEntity, this, resource));
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

    loadWorkspace: function(workspaceId, options) {
        var optionsWithDefaults = _.extend({
            fetch: true,
            required: false
        }, options);
        this.workspaceId = parseInt(workspaceId, 10);
        this.workspace = new chorus.models.Workspace({id: workspaceId});
        if (optionsWithDefaults.fetch) {
            this.handleFetchErrorsFor(this.workspace);
            this.workspace.fetch();
        }
        if (optionsWithDefaults.required) {
            this.requiredResources.add(this.workspace);
        }
    },

    _initializeHeaderAndBreadcrumbs: function() {
        this.header = this.header || new chorus.views.Header();
        if (this.workspaceId) {
            this.header.workspaceId = this.workspaceId;
        }
        var page = this;
        this.breadcrumbs = new chorus.views.BreadcrumbsView({
            breadcrumbs: _.isFunction(page.crumbs) ? _.bind(page.crumbs, page) : page.crumbs
        });
    },

    showHelp: function(e) {
        e.preventDefault();
        chorus.help();
    }
});
