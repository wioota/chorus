chorus.dialogs.JobResultDetail = chorus.dialogs.Base.extend({
    constructorName: 'JobResultDetailDialog',
    templateName: "job_result_detail",

    makeModel: function () {
        this.job = this.options.job;
        this.model = new chorus.models.JobResult({jobId: this.job.id, id: 'latest'});
        this.model.fetch();
    },

    setup: function () {
        this.title = t("job.result_details.title", {jobName: this.job.name()});
    }
});