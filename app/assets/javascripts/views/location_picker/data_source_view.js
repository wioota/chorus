//= require ./selector_view
chorus.views.LocationPicker.DataSourceView = chorus.views.LocationPicker.SelectorView.extend({
    templateName: "location_picker_data_source",
    constructorName: "LocationPickerDataSourceView",

    events: {
        "change select": "dataSourceSelected"
    },

    setup: function() {
        this.childPicker = this.options.childPicker;

        if(this.options.dataSource) {
            this.setState(this.STATES.STATIC);
        } else {
            this.collection = new chorus.collections.GpdbDataSourceSet();
            this.onceLoaded(this.collection, this.dataSourcesLoaded);
            this.collection.attributes.accessible = true;
            this.listenTo(this.collection, "fetchFailed", this.fetchFailed);
            this.collection.fetchAll();
            this.setState(this.STATES.LOADING);
        }
    },

    dataSourceSelected: function() {
        this.trigger("clearErrors");
        var selectedDataSource = this.getSelectedDataSource();
        this.setSelection(selectedDataSource);
        this.trigger('change');
        if(!selectedDataSource) {
            this.childPicker.hide();
        }
    },

    onSelection: function() {
        this.childPicker.parentSelected(this.selection);
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

    dataSourcesLoaded: function() {
        var state = (this.gpdbDataSources().length === 0) ? this.STATES.UNAVAILABLE : this.STATES.SELECT;
        this.setState(state);
    },

    gpdbDataSources: function() {
        return this.collection.filter(function(dataSource) {
            return dataSource.get("dataSourceProvider") !== "Hadoop";
        });
    }
});