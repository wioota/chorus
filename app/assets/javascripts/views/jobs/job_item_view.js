chorus.views.JobItem = chorus.views.Base.extend({
    constructorName: "JobItemView",
    templateName:"job_item",

    setup: function() {
        this._super("setup", arguments);
        this.listenTo(this.model, "invalidated", function() { this.model.fetch(); });
    },

    additionalContext: function () {
        return {
            iconUrl: this.iconUrl(),
            url: this.model.showUrl(),
            frequency: this.model.frequency(),
            stateKey: "job.state." + this.jobStateKey(),
            running: this.isRunning()
        };
    },

    postRender: function() {
        this.$(".loading_spinner").startLoading(null, {color: '#959595'});
    },

    jobStateKey: function () {
        if (this.isRunning()) {
            return 'running';
        }
        return this.model.get('enabled') ? 'scheduled' : 'disabled';
    },

    isRunning: function () {
        return this.model.get("status") === "running";
    },

    iconUrl: function () {
        var icon = this.model.get('enabled') ? 'job.png' : 'job-disabled.png';
        return "/images/jobs/" + icon;
    }
});