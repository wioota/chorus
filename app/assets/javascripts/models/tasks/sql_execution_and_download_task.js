chorus.models.SqlExecutionAndDownloadTask = chorus.models.WorkfileExecutionTask.extend({
    constructorName: "SqlExecutionAndDownloadTask",

    save: function() {
        $.fileDownload('/workfiles/' + this.attributes.workfileId + '/executions', {
            data: _.extend({
                download: true
            }, this.underscoreKeys(this.attributes)),
            httpMethod: "post",
            successCallback: _.bind(this.saved, this),
            failCallback: _.bind(this.saveFailed, this),
            cookieName: 'fileDownload_' + this.get('checkId')
        });
    },

    saved: function() {
        this.trigger("saved", this);
    },

    saveFailed: function() {
        this.trigger("saveFailed");
    },

    cancel: function() {
        this._super("cancel");
        chorus.PageEvents.broadcast("file:executionCancelled");
    }
});
