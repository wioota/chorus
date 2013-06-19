(function() {

    // states
    var HIDDEN = 0,
        LOADING = 1,
        SELECT = 2,
        STATIC = 3,
        UNAVAILABLE = 4,
        CREATE_NEW = 5,
        CREATE_NESTED = 6;

    chorus.views.SchemaPicker = chorus.views.LocationPicker.BaseView.extend({
        constructorName: "SchemaPickerView",
        templateName: "schema_picker",

        events: {
            "click .database a.new": "createNewDatabase",
            "click .database .cancel": "cancelNewDatabase",
            "click .schema a.new": "createNewSchema",
            "click .schema .cancel": "cancelNewSchema"
        },

        subviews: {
            ".data_source": "dataSourceView",
            ".database": "databaseView",
            ".schema": "schemaView"
        },

        buildSelectorViews: function() {
            this.schemaView = new chorus.views.LocationPicker.SchemaView({
                allowCreate: this.options.allowCreate
            });

            this.databaseView = new chorus.views.LocationPicker.DatabaseView({
                childPicker: this.schemaView,
                allowCreate: this.options.allowCreate,
                database: this.options.database
            });

            this.dataSourceView = new chorus.views.LocationPicker.DataSourceView({
                dataSource: this.options.dataSource,
                childPicker: this.databaseView
            });
            this.registerSubView(this.schemaView);
            this.registerSubView(this.databaseView);
            this.registerSubView(this.dataSourceView);
        },

        bindToSelectorViews: function() {
            _([this.schemaView, this.databaseView, this.dataSourceView]).each(this.bindSubviewEvents, this);
        },

        setSelectorViewDefaults: function() {
            if(_.isUndefined(this.options.showSchemaSection)) {
                this.options.showSchemaSection = true;
            }

            this.databaseView.setState(HIDDEN);
            this.schemaView.setState(HIDDEN);

            if(this.options.defaultSchema) {
                this.setSelection('dataSource', this.options.defaultSchema.database().dataSource());
                this.setSelection('database', this.options.defaultSchema.database());
                this.setSelection('schema', this.options.defaultSchema);
                this.dataSourceView.setState(LOADING);
                this.databaseView.setState(LOADING);
                this.schemaView.setState(LOADING);
            } else {
                this.setSelection('dataSource', this.options.dataSource);
                this.setSelection('database', this.options.database);
            }

            if(this.dataSourceView.selection && !this.options.database) {
                this.databaseView.fetchDatabases(this.dataSourceView.selection);
            }

            if(this.databaseView.selection) {
                this.schemaView.fetchSchemas(this.databaseView.selection);
            }
        },

        postRender: function() {
            this.$('.loading_spinner').startLoading();
            this.$("input.name").bind("textchange", _.bind(this.triggerSchemaSelected, this));
        },


        createNewDatabase: function(e) {
            e.preventDefault();
            this.trigger("clearErrors");
            this.databaseView.clearSelection();
            this.schemaView.clearSelection();
            this.databaseView.setState(CREATE_NEW);
            this.schemaView.setState(CREATE_NESTED);
            this.$(".schema input.name").val(chorus.models.Schema.DEFAULT_NAME);
        },

        createNewSchema: function(e) {
            e.preventDefault();
            this.trigger("clearErrors");
            this.schemaView.clearSelection();
            this.schemaView.setState(CREATE_NEW);
            this.$(".schema input.name").val("");
        },

        cancelNewDatabase: function(e) {
            e.preventDefault();
            this.databaseView.databasesLoaded();
            this.triggerSchemaSelected();
        },

        cancelNewSchema: function(e) {
            e.preventDefault();
            this.schemaView.schemasLoaded();
            this.triggerSchemaSelected();
        },

        schemaId: function() {
            var selectedSchema = this.schemaView.getSelectedSchema();
            return selectedSchema && selectedSchema.id;
        },

        getSelectedSchema: function() {
            return this.schemaView.selection;
        },

        getSelectedDatabase: function() {
            return this.databaseView.selection;
        },

        additionalContext: function() {
            return { options: this.options };
        }
    });
})();

