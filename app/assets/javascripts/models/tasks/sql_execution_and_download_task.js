chorus.models.SqlExecutionAndDownloadTask = chorus.models.WorkfileExecutionTask.extend({
    constructorName: "SqlExecutionAndDownloadTask",
    nestParams: false,
    paramsToSave: ['checkId', 'sql', 'schemaId', 'numOfRows', 'fileName'],

    save: function() {
        $.fileDownload(this.url(), {
            data: _.extend({
                download: true
            }, this.toJSON()),
            httpMethod: "post",
            successCallback: _.bind(this.saved, this),
            failCallback: _.bind(this.saveFailed, this),
            cookieName: 'fileDownload_' + this.get('checkId')
        });
    },

    saved: function() {
        // this always happens.
        // successCallback refers to the browser showing a save dialog,
        // not to anything about the http request
        this.trigger("saved", this);
    },

    saveFailed: function(responseHtml) {
        var responseText = $(responseHtml).text();
        this.handleRequestFailure("saveFailed", {responseText: responseText});
    },

    cancel: function() {
        this._super("cancel");
        chorus.PageEvents.broadcast("file:executionCancelled");
    },

    fileName: function() {
        return this.name();
    }
});
