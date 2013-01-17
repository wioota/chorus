chorus.views.InstanceIndexContentDetails = chorus.views.Base.extend({
    constructorName: "InstanceIndexContentDetailsView",
    templateName:"instance_index_content_details",

    setup: function(){
        this.gpdbInstances = this.options.gpdbInstances;
        this.hadoopInstances = this.options.hadoopInstances;
        this.gnipInstances = this.options.gnipInstances;

        this.bindings.add(this.gpdbInstances, 'loaded', this.render);
        this.bindings.add(this.hadoopInstances, 'loaded', this.render);
        this.bindings.add(this.gnipInstances, 'loaded', this.render);
    },

    additionalContext: function() {
        return {
            loaded: this.gpdbInstances.loaded && this.gnipInstances.loaded && this.hadoopInstances.loaded,
            count: this.gpdbInstances.length + this.hadoopInstances.length + this.gnipInstances.length
        };
    }
});