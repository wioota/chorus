chorus.models.Job = chorus.models.Base.extend({
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
        if (!this._tasks && this.get("tasks")) {
            this._tasks = new chorus.collections.JobTaskSet(this.get("tasks"), {parse: true});
        }
        return this._tasks;
    },

    runsOnDemand: function () {
        return this.get("intervalUnit") === "on_demand";
    },

    nextRunDate: function () {
        var startDate = this.get('nextRun');
        return startDate ? new Date(startDate) : new Date();
    },

    endRunDate: function () {
        var endDate = this.get('endRun');
        return endDate ? new Date(endDate) : new Date();
    },

    nextRunTime: function () {
        var hoursBase = this.nextRunDate().getHours();
        var meridiem = hoursBase - 11 > 0 ? "pm" : "am";
        var hours = meridiem === "pm" ? hoursBase - 12 : hoursBase;
        var minutes = Math.floor(this.nextRunDate().getMinutes() / 5) * 5;
        hours = hours === 0 ? 12 : hours;

        return {
            hours: hours,
            minutes: minutes,
            meridiem: meridiem
        };
    },

    disable: function () {
        this.save( {enabled: false}, { wait: true} );
    },

    enable: function () {
        this.save( {enabled: true}, { wait: true} );
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
    }
});