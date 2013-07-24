chorus.views.JobShowPageButtons = chorus.views.Base.extend({
    constructorName: "JobShowPageButtons",
    templateName: "job_show_page_buttons",

    setup: function() {
        chorus.applyPlugins(this);
        this.model.fetchIfNotLoaded();
        this.workspace = this.model.workspace();
    },

    canUpdate: function() {
        return this.workspace.canUpdate() && this.workspace.isActive();
    },

    additionalContext: function() {
        return {
            canUpdate: this.canUpdate()
        };
    }
});