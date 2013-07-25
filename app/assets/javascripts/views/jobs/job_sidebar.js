chorus.views.JobSidebar = chorus.views.Sidebar.extend({
    constructorName: "JobSidebar",
    templateName:"job_sidebar",

    events: {
        "click .disable": "disableJob",
        "click .enable": "enableJob"
    },

    disableJob: function(e) {
        e && e.preventDefault();
        this.model.save({enabled: false}, { wait: true });
    },

    enableJob: function(e) {
        e && e.preventDefault();
        this.model.save( {enabled: true}, { wait: true} );
    },

    additionalContext: function () {
        if (!this.model) {
            return {};
        }

        return {
            enabled: this.model.get('state') !== 'disabled'
        };
    }
});