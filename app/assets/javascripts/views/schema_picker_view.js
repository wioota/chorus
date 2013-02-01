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
        templateName:"schema_picker",

        events: {
            "change .instance select": "instanceSelected",
            "change .database select": "databaseSelected",
            "change .schema select": "schemaSelected",
            "click .database a.new": "createNewDatabase",
            "click .database .cancel": "cancelNewDatabase",
            "click .schema a.new": "createNewSchema",
            "click .schema .cancel": "cancelNewSchema"
        },

        setup: function () {
            //Prebind these so the BindingGroup detects duplicates each time and doesn't bind them multiple times.
            this.instanceFetchFailed = _.bind(this.fetchFailed, this, null);
            this.databaseFetchFailed = _.bind(this.fetchFailed, this, 'database');
            this.schemaFetchFailed = _.bind(this.fetchFailed, this, 'schema');

            this.sectionStates = {};

            this.setState({ instance: HIDDEN, database: HIDDEN, schema: HIDDEN });

            if (this.options.defaultSchema) {
                this.selection = {
                    schema: this.options.defaultSchema,
                    database: this.options.defaultSchema.database(),
                    instance: this.options.defaultSchema.database().instance()
                };
                this.setState({ instance: LOADING, database: LOADING, schema: LOADING });
            } else {
                this.selection = {
                    instance: this.options.instance,
                    database: this.options.database
                };
            }

            if (this.options.instance) {
                this.setState({
                    instance: STATIC,
                    database: this.options.database ? STATIC : LOADING
                });
            } else {
                this.instances = new chorus.collections.GpdbDataSourceSet();
                this.bindings.add(this.instances, "loaded", this.instancesLoaded);
                this.instances.attributes.accessible = true;
                this.bindings.add(this.instances, "fetchFailed", this.instanceFetchFailed);
                this.instances.fetchAll();

                this.setState({ instance: LOADING });
            }

            if (this.selection.instance && !this.options.database) {
                this.fetchDatabases(this.selection.instance);
            }

            if (this.selection.database) {
                this.fetchSchemas(this.selection.database);
            }
        },

        postRender:function () {
            this.restyleAllSectionsToReflectStates();

            this.$('.loading_spinner').startLoading();
            this.$("input.name").bind("textchange", _.bind(this.triggerSchemaSelected, this));
        },

        instancesLoaded: function () {
            var state = (this.gpdbDataSources().length === 0) ? UNAVAILABLE : SELECT;
            this.setState({ instance: state });
        },

        databasesLoaded: function () {
            var state = (this.databases.length === 0) ? UNAVAILABLE : SELECT;
            this.setState({ database: state });
        },

        schemasLoaded: function () {
            var state = (this.schemas.length === 0) ? UNAVAILABLE : SELECT;
            this.setState({ schema: state });
        },

        instanceSelected:function () {
            this.trigger("clearErrors");
            this.clearSelection('database');
            this.clearSelection('schema');
            var selectedInstance = this.getSelectedInstance();

            if (selectedInstance) {
                this.setSelection("instance", selectedInstance);
                this.setState({ database: LOADING });
                this.fetchDatabases(selectedInstance);
            } else {
                this.clearSelection('instance');
                this.restyleAllSectionsToReflectStates();
            }
        },

        fetchDatabases:function(selectedInstance) {
            this.databases = selectedInstance.databases();
            this.databases.fetchAllIfNotLoaded();
            this.bindings.add(this.databases, "fetchFailed", this.databaseFetchFailed);
            this.bindings.add(this.databases, "loaded", this.databasesLoaded);
        },

        databaseSelected: function () {
            this.trigger("clearErrors");
            this.clearSelection('schema');
            var selectedDatabase = this.getSelectedDatabase();

            if (selectedDatabase) {
                this.setSelection("database", selectedDatabase);
                this.setState({ schema: LOADING });
                this.fetchSchemas(selectedDatabase);
            } else {
                this.clearSelection('database');
                this.restyleAllSectionsToReflectStates();
            }
        },

        fetchSchemas: function(selectedDatabase) {
            this.schemas = selectedDatabase.schemas();
            this.schemas.fetchAllIfNotLoaded();
            this.bindings.add(this.schemas, "fetchFailed", this.schemaFetchFailed);
            this.bindings.add(this.schemas, "loaded", this.schemasLoaded);
        },

        schemaSelected:function () {
            this.trigger("clearErrors");
            this.setSelection("schema", this.getSelectedSchema());
        },

        createNewDatabase:function (e) {
            e.preventDefault();
            this.trigger("clearErrors");
            this.clearSelection('database');
            this.clearSelection("schema");
            this.setState({ database: CREATE_NEW, schema: CREATE_NESTED });
            this.$(".schema input.name").val(chorus.models.Schema.DEFAULT_NAME);
        },

        createNewSchema:function (e) {
            e.preventDefault();
            this.trigger("clearErrors");
            this.$('.schema select option:selected').prop("selected", false);
            this.setState({ schema: CREATE_NEW });
            this.$(".schema input.name").val("");
        },

        cancelNewDatabase: function (e) {
            e.preventDefault();
            this.databasesLoaded();
            this.triggerSchemaSelected();
        },

        cancelNewSchema:function (e) {
            e.preventDefault();
            this.schemasLoaded();
            this.triggerSchemaSelected();
        },

        fieldValues: function () {
            var selectedInstance = this.selection.instance;
            var selectedDatabase = this.selection.database;
            var selectedSchema   = this.selection.schema;

            var attrs = {
                instance: selectedInstance && selectedInstance.get("id")
            };

            if (selectedDatabase && selectedDatabase.get('id')) {
                attrs.database = selectedDatabase.get("id");
            } else if (selectedDatabase && selectedDatabase.get("name")) {
                attrs.databaseName = selectedDatabase.get('name');
            } else {
                attrs.databaseName = this.$(".database input.name:visible").val();
            }

            if (selectedSchema) {
                attrs.schema = selectedSchema.get("id");
            } else {
                attrs.schemaName = this.$(".schema input.name:visible").val();
            }
            return attrs;
        },

        schemaId: function() {
            var selectedSchema = this.getSelectedSchema();
            return selectedSchema && selectedSchema.id;
        },

        restyleAllSectionsToReflectStates: function() {
            var states = _.clone(this.sectionStates);

            var hideTheRest = false;
            _.each(["instance", "database", "schema"], function(sectionName) {
                var state = hideTheRest ? HIDDEN : states[sectionName];
                this.restyleSection(sectionName, state);

                var waitingForSelect = (state === SELECT && !this.selection[sectionName]);
                if (_.contains([UNAVAILABLE, LOADING, HIDDEN], state) || waitingForSelect) hideTheRest = true;
            }, this);
        },

        restyleSection: function(type, state) {
            var section = this.$("." + type);
            section.removeClass("hidden");
            section.find("a.new").removeClass("hidden");
            section.find(".loading_text, .select_container, .create_container, .unavailable").addClass("hidden");
            section.find(".create_container").removeClass("show_cancel_link");

            this.rebuildEmptySelect(type);

            switch (state) {
                case LOADING:
                    section.find(".loading_text").removeClass("hidden");
                    break;
                case SELECT:
                    section.find(".select_container").removeClass("hidden");
                    var currentSelection = this.selection[type];
                    this.populateSelect(type, currentSelection && currentSelection.id);
                    break;
                case CREATE_NEW:
                    section.find(".create_container").removeClass("hidden");
                    section.find(".create_container").addClass("show_cancel_link");
                    section.find("a.new").addClass("hidden");
                    break;
                case CREATE_NESTED:
                    section.find(".create_container").removeClass("hidden");
                    section.find("a.new").addClass("hidden");
                    break;
                case UNAVAILABLE:
                    section.find(".unavailable").removeClass("hidden");
                    break;
                case HIDDEN:
                    section.addClass("hidden");
                    break;
            }
        },

        setState: function(params) {
            _.each(params, function(stateValue, sectionName) {
                this.sectionStates[sectionName] = stateValue;
            }, this);

            this.restyleAllSectionsToReflectStates();
        },

        getSelectedInstance: function() {
            return this.instances && this.instances.get(this.$('.instance select option:selected').val());
        },

        getSelectedDatabase : function() {
            return this.databases && this.databases.get(this.$('.database select option:selected').val());
        },

        getSelectedSchema: function() {
            return this.schemas && this.schemas.get(this.$('.schema select option:selected').val());
        },

        fetchFailed: function(type, collection) {
            if (type) { this.clearSelection(type); }
            this.trigger("error", collection);
        },

        setSelection: function(type, value) {
            this.selection[type] = value;
            this.triggerSchemaSelected();
        },
        
        clearSelection: function(type) {
            delete this.selection[type];
            this.triggerSchemaSelected();
        },

        rebuildEmptySelect: function(type) {
            var select = this.$("." + type).find("select");
            select.html($("<option/>").prop('value', '').text(t("sandbox.select_one")));
            return select;
        },

        gpdbDataSources: function() {
            return this.instances.filter(function(instance) {
                return instance.get("instanceProvider") !== "Hadoop";
            });
        },

        triggerSchemaSelected: function() {
            this.trigger("change", this.ready());
        },

        ready: function () {
            var attrs = this.fieldValues();
            return !!(attrs.instance && (attrs.database || attrs.databaseName) && (attrs.schema || attrs.schemaName));
        },

       populateSelect: function(type, defaultValue) {
            var models = (type === "instance") ? this.gpdbDataSources() : this[type + "s"].models;
            var select = this.rebuildEmptySelect(type);

            _.each(this.sortModels(models), function(model) {
                var option = $("<option/>")
                    .prop("value", model.get("id"))
                    .text(Handlebars.Utils.escapeExpression(model.get("name")));
                if(model.get("id") === defaultValue) {
                    option.attr("selected", "selected");
                }
                select.append(option);
            });

            if (defaultValue !== undefined && !_.contains(_.pluck(models, "id"), defaultValue)) {
                if (type === "schema") this.showErrorForMissingSchema();
                this.clearSelection(type);
            }

            chorus.styleSelect(select);
        },

        showErrorForMissingSchema: function() {
            this.schemas.serverErrors = {fields: {base: {SCHEMA_MISSING: {name: this.selection.schema.name()}}}};
            this.trigger("error", this.schemas);
        },

        sortModels: function(models) {
            return _.clone(models).sort(function(a, b) {
                return naturalSort(a.get("name").toLowerCase(), b.get("name").toLowerCase());
            });
        },

        additionalContext: function () {
            return { options: this.options };
        }
    });
})();

