chorus.dialogs.InstanceUsage = chorus.dialogs.Base.extend({
    constructorName: "InstanceUsage",

    templateName: "instance_usage",
    title: t("instances.usage.title"),
    useLoadingSection: true,
    additionalClass: 'with_sub_header',

    setup: function() {
        this.usage = this.resource = this.options.instance.usage();
        this.usage.fetchIfNotLoaded();
        this.requiredResources.push(this.usage);
    },

    additionalContext: function(context) {
        var online = this.model.get("state") !== 'offline';
        _.each(context.workspaces, function(workspace) {
            if(online) {
                workspace.formattedSize = I18n.toHumanSize(workspace.sizeInBytes, {precision: 0, format: "%n %u"});
            } else {
                workspace.percentageUsed = 0;
                workspace.formattedSize = t('instances.usage.offline');
            }
        });

        if(online) {
            return {
                formattedSandboxesSize: I18n.toHumanSize(context.sandboxesSizeInBytes, {precision: 0, format: "%n %u"})
            };
        }
        else {
            return {formattedSandboxesSize: t('instances.usage.offline')};
        }
    }
});