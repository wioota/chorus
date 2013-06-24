//= require ./selector_view
chorus.views.LocationPicker.DataSourceView = chorus.views.LocationPicker.SelectorView.extend({
    templateName: "location_picker_data_source",
    constructorName: "LocationPickerDataSourceView",

    events: {
        "change select": "dataSourceSelected"
    },

    setup: function() {
        this._super('setup');

        if(this.options.dataSource) {
            this.setState(this.STATES.STATIC);
        } else {
            this.collection = new (chorus.collections.Base.include(chorus.Mixins.MultiModelSet))();
            this.dataSourceCollections = [];
            this.collectGpdbDataSources();

            if (this.options.showHdfsDataSources) {
                this.collectHdfsDataSources();
            }
            this.setState(this.STATES.LOADING);
        }
    },

    collectHdfsDataSources: function() {
        this.hdfsDataSources = new chorus.collections.HdfsDataSourceSet();
        this.dataSourceCollections.push(this.hdfsDataSources);
        this.onceLoaded(this.hdfsDataSources, this.resourcesLoaded);
        this.listenTo(this.hdfsDataSources, "fetchFailed", this.fetchFailed);
        this.hdfsDataSources.fetchAll();
    },

    collectGpdbDataSources: function() {
        this.gpdbDataSources = new chorus.collections.GpdbDataSourceSet();
        this.gpdbDataSources.attributes.accessible = true;
        this.dataSourceCollections.push(this.gpdbDataSources);
        this.onceLoaded(this.gpdbDataSources, this.resourcesLoaded);
        this.listenTo(this.gpdbDataSources, "fetchFailed", this.fetchFailed);
        this.gpdbDataSources.fetchAll();
    },

    dataSourceSelected: function() {
        this.trigger("clearErrors");
        var selectedDataSource = this.getSelectedDataSource();
        this.setSelection(selectedDataSource);
        this.trigger('change');
        if(!selectedDataSource || selectedDataSource.entityType === "hdfs_data_source") {
            this.childPicker.hide();
        }
    },

    onSelection: function() {
        if(this.selection && this.selection.entityType !== "hdfs_data_source") {
            this.childPicker.parentSelected(this.selection);
        }
    },

    getSelectedDataSource: function() {
        var dataSourceId = this.$('select option:selected').val();
        return this.collection && this.collection.get(dataSourceId);
    },

    additionalContext: function() {
        return {
            dataSource: this.options.dataSource
        };
    },

    allDataSourcesLoaded: function() {
        return _(this.dataSourceCollections).all(function(dataSourceSet) {
            return dataSourceSet.loaded;
        });
    },

    resourcesLoaded: function() {
        if (this.allDataSourcesLoaded()) {
            var models = this.dataSourceCollections.map(function(dataSourceSet) {
                return dataSourceSet.models;
            });

            this.collection.reset(_(models).flatten());
            var state = (this.collection.length === 0) ? this.STATES.UNAVAILABLE : this.STATES.SELECT;
            this.setState(state);
        }
    },

    fieldValues: function() {
        return {
            dataSource: this.selection && this.selection.get("id")
        };
    },

    selectionIsMissing: function(defaultValue) {
        var dataSourceExists = _(this.collection.models).any(function(dataSourceSet) {
            return (defaultValue !== undefined) && (dataSourceSet.get("id") === defaultValue.id) && (dataSourceSet.get("entityType") === defaultValue.entityType);
        });
        return !dataSourceExists;
    },

    modelIsSelected: function(defaultValue, model) {
        var modelIsSelected = defaultValue && model.get("id") === defaultValue.id && model.get("entityType") === defaultValue.entityType;
        return modelIsSelected;
    },

    ready: function() {
        var attrs = this.fieldValues();
        return !!attrs.dataSource;
    }
});