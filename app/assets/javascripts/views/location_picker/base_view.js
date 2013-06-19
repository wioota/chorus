chorus.views.LocationPicker.BaseView = chorus.views.Base.extend({
    setup: function() {
        this.buildSelectorViews();
        this.bindToSelectorViews();
        this.setSelectorViewDefaults();
    },

    bindSubviewEvents: function(subview) {
        this.listenTo(subview, 'change', this.triggerSchemaSelected);
        this.listenTo(subview, 'error', function(collection) {
            this.trigger('error', collection);
        });
        this.listenTo(subview, 'clearErrors', function() {
            this.trigger('clearErrors');
        });
    },

    setSelection: function(type, value) {
        this.getPickerSubview(type).setSelection(value);
        this.triggerSchemaSelected();
    },

    triggerSchemaSelected: function() {
        this.trigger("change", this.ready());
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

    STATES: {
        HIDDEN: 0,
        LOADING: 1,
        SELECT: 2,
        STATIC: 3,
        UNAVAILABLE: 4,
        CREATE_NEW: 5,
        CREATE_NESTED: 6
    }
});