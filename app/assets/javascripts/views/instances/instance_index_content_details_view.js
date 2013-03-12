chorus.views.InstanceIndexContentDetails = chorus.views.Base.extend({
    constructorName: "InstanceIndexContentDetailsView",
    templateName:"instance_index_content_details",

    events: {
        "click a.select_all": "selectAll",
        "click a.select_none": "selectNone"
    },

    setup: function(){
        this.dataSources = this.options.dataSources;
        this.hdfsDataSources = this.options.hdfsDataSources;
        this.gnipDataSources = this.options.gnipDataSources;

        this.bindings.add(this.dataSources, 'loaded', this.render);
        this.bindings.add(this.hdfsDataSources, 'loaded', this.render);
        this.bindings.add(this.gnipDataSources, 'loaded', this.render);
    },

    selectAll: function(e) {
        e.preventDefault();
        chorus.PageEvents.broadcast("selectAll");
    },

    selectNone: function(e) {
        e.preventDefault();
        chorus.PageEvents.broadcast("selectNone");
    },

    additionalContext: function() {
        return {
            loaded: this.dataSources.loaded && this.gnipDataSources.loaded && this.hdfsDataSources.loaded,
            count: this.dataSources.length + this.hdfsDataSources.length + this.gnipDataSources.length
        };
    }
});