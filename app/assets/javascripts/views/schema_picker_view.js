(function() {

    // states
    var HIDDEN = 0,
        LOADING = 1,
        SELECT = 2,
        STATIC = 3,
        UNAVAILABLE = 4,
        CREATE_NEW = 5,
        CREATE_NESTED = 6;

    chorus.views.SchemaPicker = chorus.views.Base.extend({
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

        setup: function() {
            this.initialDataSource = this.options.dataSource;

            this.schemaView = new chorus.views.LocationPicker.SchemaView({
                allowCreate: this.options.allowCreate
            });

            this.databaseView = new chorus.views.LocationPicker.DatabaseView({
                childPicker: this.schemaView,
                allowCreate: this.options.allowCreate,
                database: this.options.database
            });

            this.dataSourceView = new chorus.views.LocationPicker.DataSourceView({
                dataSource: this.initialDataSource,
                childPicker: this.databaseView
            });

            _([this.schemaView, this.databaseView, this.dataSourceView]).each(function(subview) {
                this.listenTo(subview, 'change', this.triggerSchemaSelected);
                this.listenTo(subview, 'error', function(collection) { this.trigger('error', collection); });
                this.listenTo(subview, 'clearErrors', function() { this.trigger('clearErrors'); });
            }, this);

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

        fieldValues: function() {
            var selectedDataSource = this.dataSourceView.selection;
            var selectedDatabase = this.databaseView.selection;
            var selectedSchema = this.schemaView.selection;

            var attrs = {
                dataSource: selectedDataSource && selectedDataSource.get("id")
            };

            if(selectedDatabase && selectedDatabase.get('id')) {
                attrs.database = selectedDatabase.get("id");
            } else if(selectedDatabase && selectedDatabase.get("name")) {
                attrs.databaseName = selectedDatabase.get('name');
            } else {
                attrs.databaseName = this.$(".database input.name:visible").val();
            }

            if(selectedSchema) {
                attrs.schema = selectedSchema.get("id");
            } else {
                attrs.schemaName = this.$(".schema input.name:visible").val();
            }
            return attrs;
        },

        schemaId: function() {
            var selectedSchema = this.schemaView.getSelectedSchema();
            return selectedSchema && selectedSchema.id;
        },

        // TODO: FIX ME
        getSectionsToRestyle: function() {
            return this.options.showSchemaSection ? ["dataSource", "database", "schema"] : ["dataSource", "database"];
        },

        getPickerSubview: function(type) {
            switch (type) {
                case "dataSource":
                    return this.dataSourceView;
                case "database":
                    return this.databaseView;
                case "schema":
                    return this.schemaView;
            }
        },

        getSelectedSchema: function() {
            return this.schemaView.getSelectedSchema();
        },

        setSelection: function(type, value) {
            this.getPickerSubview(type).setSelection(value);
            this.triggerSchemaSelected();
        },

        triggerSchemaSelected: function() {
            this.trigger("change", this.ready());
        },

        ready: function() {
            var attrs = this.fieldValues();
            return !!(attrs.dataSource && (attrs.database || attrs.databaseName) && (attrs.schema || attrs.schemaName || !this.options.showSchemaSection));
        },

        additionalContext: function() {
            return { options: this.options };
        }
    });
})();

