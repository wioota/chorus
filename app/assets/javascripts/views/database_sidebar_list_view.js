chorus.views.DatabaseSidebarList = chorus.views.Base.extend({
    constructorName: "DatabaseSidebarListView",
    events: {
        "click .context a": "contextClicked",
        "click .no_credentials .add_credentials": "launchAddCredentialsDialog"
    },

    setup: function() {
        this.setSchema(this.options.schema);
        this.subscribePageEvent("workfile:changed", this.workfileChanged);
    },

    additionalContext: function() {
        if(!this.schema) {
            return {
                schemaAssociated: false
            };
        } else {
            return {
                schemaAssociated: true,
                schemaLink: chorus.helpers.linkTo("#", this.schema.get('name')),
                schemas: this.schemas.map(function(schema) {
                    return {
                        id: schema.get("id"),
                        name: schema.get("name"),
                        isCurrent: this.schema.get('id') === schema.get('id')
                    };
                }, this),
                noCredentials: this.schemas.statusCode === 403,
                noCredentialsWarning: chorus.helpers.safeT("dataset.credentials.missing.body", {
                    linkText: chorus.helpers.linkTo("#", t("dataset.credentials.missing.linkText"), {'class': 'add_credentials'}),
                    dataSourceName: this.schema.database() && this.schema.database().instance().name()
                })
            };
        }
    },

    setSchemaToCurrentWorkspace: $.noop,
    fetchResourceAfterSchemaSelected: $.noop,
    searchTextChanged: $.noop,

    teardown: function() {
        this.$("li").qtip("destroy");
        this._super("teardown");
    },

    postRender: function() {
        this.setupSchemaMenu();
        this.closeQtipOnScroll();
        this.setupDragging();
    },

    setupSchemaMenu: function() {
        chorus.menu(this.$(".context a"), {
            content: this.$(".schema_menu_container").html(),
            container: $('#sidebar_wrapper'),
            contentEvents: {
                'a.schema': _.bind(this.schemaSelected, this)
            },

            classes: "sidebar_schema_picker",

            // Hard code this qtips tip length so it hides the underlying menu
            style: {
                tip: {
                    mimic: "top center",
                    width: 20,
                    height: 10
                }
            }
        });
    },

    closeQtipOnScroll: function() {
        chorus.page && chorus.page.sidebar && chorus.page.sidebar.bind("scroll", _.bind(function() {
            $(".hover").removeClass("hover");
            this.closeQtip();
        }, this));
    },

    setupDragging: function() {
        this.$("ul.list li").draggable({
            containment: "window",
            appendTo: "body",
            helper: this.dragHelper
        });
    },

    dragHelper: function(e) {
        return $(e.currentTarget).clone().addClass("drag_helper");
    },

    schemaSelected: function(e) {
        var schemaId = $(e.target).data("id");
        if(schemaId === "workspaceSchema") {
            this.setSchemaToCurrentWorkspace();
            this.fetchResourceAfterSchemaSelected();

        } else {
            this.schema = this.schemas.get(schemaId);
            this.fetchResourceAfterSchemaSelected();
        }

        this.render();
    },

    insertText: function(cid, e) {
        e && e.preventDefault();
        var model = this.collection.get(cid);
        chorus.PageEvents.broadcast("file:insertText", model.toText());
    },

    closeQtip: function() {
        $(".workfile_show_sidebar li:hover a").trigger("mouseleave");
        $(".workfile_show_sidebar .context a").trigger("unfocus");
    },

    contextClicked: function(e) {
        e.preventDefault();
    },

    workfileChanged: function(workfile) {
        var executionSchema = workfile.executionSchema();
        if(!this.schema || (executionSchema.id && executionSchema.id !== this.schema.id)) {
            this.setSchema(new chorus.models.Schema(executionSchema));
        }
    },

    setSchema: function(schema) {
        var oldSchema = this.schema;
        this.schema = schema;
        if(this.schema && (!oldSchema || oldSchema.database().id !== this.schema.database().id)) {
            this.schemas = this.schema.database().schemas();
            this.requiredResources.add(this.schemas);
            this.schemas.fetchAll();
            this.fetchResourceAfterSchemaSelected();
        }
    },

    launchAddCredentialsDialog: function(e) {
        e && e.preventDefault();
        var instance = new chorus.models.GpdbDataSource({id: this.schema.get("instanceId")});
        new chorus.dialogs.InstanceAccount({ instance: instance, title: t("instances.sidebar.add_credentials"), reload: true }).launchModal();
    }
});
