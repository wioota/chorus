chorus.views.DataSourceIndexContentDetails = chorus.views.Base.include(
        chorus.Mixins.BoundForMultiSelect
    ).extend({
    constructorName: "DataSourceIndexContentDetailsView",
    templateName:"data_source_index_content_details",
    additionalClass: "action_bar_primary",

    events: {
        "click button.add_data_source": "launchAddDataSourceDialog"
    },

    setup: function(){
        this.dataSources = this.options.dataSources;
        this.hdfsDataSources = this.options.hdfsDataSources;
        this.gnipDataSources = this.options.gnipDataSources;

        this.listenTo(this.dataSources, 'loaded', this.render);
        this.listenTo(this.hdfsDataSources, 'loaded', this.render);
        this.listenTo(this.gnipDataSources, 'loaded', this.render);
    },

    additionalContext: function() {
        return {
            loaded: this.dataSources.loaded && this.gnipDataSources.loaded && this.hdfsDataSources.loaded,
            count: this.dataSources.length + this.hdfsDataSources.length + this.gnipDataSources.length
        };
    },

    launchAddDataSourceDialog: function(e) {
        e.preventDefault();
        var dialog = new chorus.dialogs.DataSourcesNew();
        dialog.launchModal();
    }

});