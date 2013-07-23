chorus.views.JobSidebar = chorus.views.Sidebar.extend({
    constructorName: "JobSidebar",
    templateName:"job_sidebar",

    additionalContext: function () {
        if (!this.model) {
            return {};
        }

        return {
            enabled: this.model.get('state') !== 'disabled'
        };
    }
});