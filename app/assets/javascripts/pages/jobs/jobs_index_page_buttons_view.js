chorus.views.JobIndexPageButtons = chorus.views.Base.extend({
    constructorName: "JobIndexPageButtons",
    templateName: "job_index_page_buttons",

    setup: function() {
        chorus.applyPlugins(this);
        this.model.fetchIfNotLoaded();
    },

    canUpdate: function() {
        return this.model.loaded && this.model.canUpdate() && this.model.isActive();
    },

    additionalContext: function() {
        return {
            canUpdate: this.canUpdate()
        };
    }
});