chorus.models.SqlExecutionAndDownloadTask = chorus.models.WorkfileExecutionTask.extend({
    constructorName: "SqlExecutionAndDownloadTask",

    save: function() {
        $.fileDownload('/workfiles/' + this.attributes.workfileId + '/executions', {
            data: _.extend({
                download: true
            }, this.underscoreKeys(this.attributes)),
            httpMethod: "post"
        });
    },

    saved: function() {
        this.trigger("saved", this);
        this.trigger("change");
    },

    saveFailed: function() {
        this.trigger("saveFailed");
    },

    cancel: function() {
        this._super("cancel");
        chorus.PageEvents.broadcast("file:executionCancelled");
    }
});
