chorus.dialogs.JobResultDetail = chorus.dialogs.Base.extend({
    constructorName: 'JobResultDetailDialog',
    templateName: "job_result_detail_dialog",
    additionalClass: "dialog_wide",

    makeModel: function () {
        if (this.model) {
            this.job = new chorus.models.Job(this.options.model.get("job"));
        } else {
            this.job = this.options.job;
            this.model = new chorus.models.JobResult({jobId: this.job.id, id: 'latest'});
            this.model.fetch();
        }
    },

    setup: function () {
        this.title = t("job.result_details.title", {jobName: this.job.name()});
        this.render();
    },

    additionalContext: function () {        
        return {
            lastRunStatusKey: this.job.lastRunStatusKey(),
            lastRunStatusStyle: this.jobRunStatusStyle(),
            statusDisplayMessage: this.taskStatusMessage,
            statusDisplayClass: this.taskStatusClass
        };
    },

    // map success | failure status to css classes
    jobRunStatusStyle: function () {
        return this.job.get("lastRunFailed") ? "failure" : "success";
    },
    
    // taskStatus: map the success | failure status to user-facing text

    taskStatusMessage: function () {
        var status = this.status;
        if (status === "success" ) {
            return t("job.result_details.status_success");
        }
        else if (status === "failure") {
            return t("job.result_details.status_failure");
        }
    },
    
    // map success | failure status to css classes
    taskStatusClass: function () {
        var status = this.status;
        if (status === "success" ) {
            return ("success");
        }
        else if (status === "failure") {
            return ("failure");
        }
    }

});