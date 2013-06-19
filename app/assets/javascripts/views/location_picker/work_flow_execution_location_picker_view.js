chorus.views.WorkFlowExecutionLocationPicker = chorus.views.LocationPicker.BaseView.extend({
    constructorName: 'WorkFlowExecutionLocationPicker',
    templateName: "execution_location_picker",

    subviews: {
        ".data_source": "dataSourceView",
        ".database": "databaseView"
    },

    buildSelectorViews: function() {
        this.databaseView = new chorus.views.LocationPicker.DatabaseView({
            database: this.options.database
        });

        this.dataSourceView = new chorus.views.LocationPicker.DataSourceView({
            dataSource: this.options.dataSource,
            childPicker: this.databaseView
        });
        this.registerSubView(this.databaseView);
        this.registerSubView(this.dataSourceView);
    },

    bindToSelectorViews: function() {
        _([this.databaseView, this.dataSourceView]).each(this.bindSubviewEvents, this);
    },

    setSelectorViewDefaults: function() {
        this.databaseView.setState(this.STATES.HIDDEN);
        this.setSelection('dataSource', this.options.dataSource);
        this.setSelection('database', this.options.database);
        if(this.dataSourceView.selection && !this.options.database) {
            this.databaseView.fetchDatabases(this.dataSourceView.selection);
        }
    },

    getSelectedDatabase: function() {
        return this.options.defaultSchema.database();
    }
});