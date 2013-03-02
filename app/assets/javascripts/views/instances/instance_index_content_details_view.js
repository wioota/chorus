chorus.views.InstanceIndexContentDetails = chorus.views.Base.extend({
    constructorName: "InstanceIndexContentDetailsView",
    templateName:"instance_index_content_details",

    events: {
        "click a.select_all": "selectAll",
        "click a.select_none": "selectNone"
    },

    setup: function(){
        this.dataSources = this.options.dataSources;
        this.hadoopInstances = this.options.hadoopInstances;
        this.gnipInstances = this.options.gnipInstances;

        this.bindings.add(this.dataSources, 'loaded', this.render);
        this.bindings.add(this.hadoopInstances, 'loaded', this.render);
        this.bindings.add(this.gnipInstances, 'loaded', this.render);
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
            loaded: this.dataSources.loaded && this.gnipInstances.loaded && this.hadoopInstances.loaded,
            count: this.dataSources.length + this.hadoopInstances.length + this.gnipInstances.length
        };
    }
});