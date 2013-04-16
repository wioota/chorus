chorus.views.DataSourceIndexContentDetails = chorus.views.Base.extend({
    constructorName: "DataSourceIndexContentDetailsView",
    templateName:"data_source_index_content_details",

    events: {
        "click a.select_all": "selectAll",
        "click a.select_none": "selectNone",
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

    selectAll: function(e) {
        e.preventDefault();
        chorus.PageEvents.trigger("selectAll");
    },

    selectNone: function(e) {
        e.preventDefault();
        chorus.PageEvents.trigger("selectNone");
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