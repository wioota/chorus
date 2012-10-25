chorus.views.InstanceIndexContentDetails = chorus.views.Base.extend({
    constructorName: "InstanceIndexContentDetailsView",
    templateName:"instance_index_content_details",

    additionalContext: function() {
        var gpdbInstances = this.options.gpdbInstances;
        var hadoopInstances = this.options.hadoopInstances;
        var gnipInstances = this.options.gnipInstances;

        this.requiredResources.add(gpdbInstances);
        this.requiredResources.add(hadoopInstances);
        this.requiredResources.add(gnipInstances);

        return {
            loaded: gpdbInstances.loaded && hadoopInstances.loaded && gnipInstances.loaded,
            count: gpdbInstances.models.length + hadoopInstances.models.length + gnipInstances.models.length
        }
    }
});