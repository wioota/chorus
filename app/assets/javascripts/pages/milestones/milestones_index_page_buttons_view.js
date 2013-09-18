chorus.views.MilestonesIndexPageButtons = chorus.views.Base.extend({
    constructorName: "MilestoneIndexPageButtons",
    templateName: "milestones_index_page_buttons",

    events: {
        'click button.create_milestone': 'launchCreateMilestoneDialog'
    },

    setup: function() {
        chorus.applyPlugins(this);
        this.model.fetchIfNotLoaded();
    },

    canUpdate: function() {
        return this.model.loaded && this.model.canUpdate() && this.model.isActive();
    },

    launchCreateMilestoneDialog: function () {
        var dialog = new chorus.dialogs.ConfigureMilestone({ workspace: {id: this.model.id} });
        dialog.launchModal();
    },

    additionalContext: function() {
        return {
            canUpdate: this.canUpdate()
        };
    }
});