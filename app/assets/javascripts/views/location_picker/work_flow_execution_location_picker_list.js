chorus.views.WorkFlowExecutionLocationPickerList = chorus.views.Base.extend({
    constructorName: 'WorkFlowExecutionLocationPickerList',
    templateName: "execution_location_picker_list",

    setup: function () {
        this.pickers = [new chorus.views.WorkFlowExecutionLocationPicker(this.options)];
        this.registerSubView(this.pickers[0]);
        this.listenTo(this.pickers[0], 'change', function () {
           this.trigger('change');
        });
    },

    postRender: function() {
        _.each(this.pickers, function(view) {
            this.$el.append(view.render().el);
        }, this);
    },

    ready: function () {
        return _.every(this.pickers, function (picker) {
            return picker.ready();
        }, this);
    },

    getSelectedDataSources: function () {
        return [this.pickers[0].getSelectedDataSource()];
    },

    getSelectedDatabases: function () {
        return [this.pickers[0].getSelectedDatabase()];
    },

    getSelectedLocations: function () {
        return _.map(this.pickers, function (picker) {
            return picker.isHdfs() ? picker.getSelectedDataSource() : picker.getSelectedDatabase();
        });
    },

    getSelectedLocationParams: function () {
        return _.map(this.getSelectedLocations(), function (dataSource) {
            return {
                id: dataSource.id,
                entity_type: dataSource.get('entityType')
            };
        });
    }
});