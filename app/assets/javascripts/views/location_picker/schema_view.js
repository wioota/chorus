chorus.views.LocationPicker.SchemaView = chorus.views.LocationPicker.SelectorView.extend({
    templateName: "location_picker_schema",
    constructorName: "LocationPickerSchemaView",

    events: {
        "change select": "schemaSelected"
    },

    setup: function() {
    },

    additionalContext: function() {
        return {
            allowCreate: this.options.allowCreate
        };
    },

    schemasLoaded: function() {
        if (this.stateValue !== this.STATES.HIDDEN) {
            var state = (this.collection.length === 0) ? this.STATES.UNAVAILABLE : this.STATES.SELECT;
            this.setState(state);
        }
    },

    onFetchFailed: function() {
        this.clearSelection();
    },

    fetchSchemas: function(selectedDatabase) {
        this.collection = selectedDatabase.schemas();
        this.collection.fetchAllIfNotLoaded();
        this.setState(this.STATES.LOADING);
        this.listenTo(this.collection, "fetchFailed", this.fetchFailed);
        this.onceLoaded(this.collection, this.schemasLoaded);
    },

    schemaSelected: function() {
        this.options.parent.trigger("clearErrors");
        this.selection = this.getSelectedSchema();
        this.options.parent.triggerSchemaSelected();
    },

    getSelectedSchema: function() {
        return this.collection && this.collection.get(this.$('select option:selected').val());
    }
});