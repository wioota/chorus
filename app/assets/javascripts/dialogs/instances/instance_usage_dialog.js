chorus.dialogs.InstanceUsage = chorus.dialogs.Base.extend({
    constructorName: "InstanceUsage",

    templateName:"instance_usage",
    title:t("instances.usage.title"),
    useLoadingSection:true,
    additionalClass:'with_sub_header',

    setup:function () {
        this.usage = this.resource = this.options.instance.usage();
        this.usage.fetchIfNotLoaded();
        this.requiredResources.push(this.usage);

        if (this.model.stateText() === 'Offline') {
            this.usage = _.map(this.usage.get("workspaces"), function(ea) {
                ea.size = 'Offline';
                ea.percentageUsed = 0;
            });
        }
    }
});