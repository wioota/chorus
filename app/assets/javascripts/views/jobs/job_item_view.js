chorus.views.JobItem = chorus.views.Base.extend({
    constructorName: "JobItemView",
    templateName:"job_item",

    setup: function() {
        this._super("setup", arguments);
        this.listenTo(this.model, "invalidated", function() { this.model.fetch(); });
    },

    additionalContext: function () {
        return {
            iconUrl: "/images/jobs/job.png",
            url: this.model.showUrl(),
            frequency: this.frequency(),
            stateKey: "job.state." + this.model.get("state"),
            running: this.model.get("state") === "running"
        };
    },

    postRender: function() {
        this.$(".loading_spinner").startLoading(null, {color: '#959595'});
    },

    frequency: function () {
        if (this.model.runsOnDemand()) {
            return t("job.frequency.on_demand");
        } else {
            return t("job.frequency.on_schedule",
                {
                    intervalValue: this.model.get('intervalValue'),
                    intervalUnit: this.model.get('intervalUnit')
                }
            );
        }
    }
});