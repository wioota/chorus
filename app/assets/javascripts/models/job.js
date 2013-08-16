chorus.models.Job = chorus.models.Base.extend({
    entityType: "Job",
    constructorName: "Job",
    urlTemplate: "workspaces/{{workspace.id}}/jobs/{{id}}",
    showUrlTemplate: "workspaces/{{workspace.id}}/jobs/{{id}}",

    workspace: function() {
        if (!this._workspace && this.get("workspace")) {
            this._workspace = new chorus.models.Workspace(this.get("workspace"));
        }
        return this._workspace;
    },
    
    tasks: function () {
        return new chorus.collections.JobTaskSet(this.get("tasks"), {parse: true});
    },

    runsOnDemand: function () {
        return this.get("intervalUnit") === "on_demand";
    },

    nextRunDate: function () {
        var startDate = this.get('nextRun');
        return startDate ? moment(startDate).zone(startDate) : moment().add(1, 'hour');
    },

    endRunDate: function () {
        var endDate = this.get('endRun');
        return endDate ? moment(endDate).zone(endDate) : moment().add(1, 'hour');
    },

    toggleEnabled: function (callbacks) {
        this.get('enabled') ? this.disable(callbacks) : this.enable(callbacks);
    },

    disable: function (callbacks) {
        this.save( {enabled: false}, _.extend({}, callbacks, { wait: true}) );
    },

    enable: function (callbacks) {
        this.save( {enabled: true}, _.extend({}, callbacks, { wait: true}) );
    },

    frequency: function () {
        if (this.runsOnDemand()) {
            return t("job.frequency.on_demand");
        } else {
            return t("job.frequency.on_schedule",
                {
                    intervalValue: this.get('intervalValue'),
                    intervalUnit: this.get('intervalUnit')
                }
            );
        }
    },

    run: function () {
        var name = this.name();
        function saveSucceeded(){ chorus.toast('job.running_toast', {jobName: name}); }
        function saveFailed(){ chorus.toast('job.not_running_toast', {jobName: name}); }

        this.save(
            {running_as_demanded: true},
            {success: saveSucceeded, error: saveFailed}
        );
    },

    stop: function () {
        var name = this.name();
        function saveSucceeded(){ chorus.toast('job.stopping_toast', {jobName: name}); }
        function saveFailed(){ chorus.toast('job.not_stopping_toast', {jobName: name}); }

        this.save(
            {kill: true},
            {success: saveSucceeded, error: saveFailed}
        );
    },

    isRunning: function () {
        return (this.get("status") === "running") || (this.get("status") === "enqueued");
    },

    lastRunLinkKey: function () {
        return this.get('lastRunFailed') ? "job.show_errors" : "job.show_details";
    },

    owner: function() {
        if (!this._owner) {
            this._owner = new chorus.models.User(this.get("owner"));
        }
        return this._owner;
    }
});