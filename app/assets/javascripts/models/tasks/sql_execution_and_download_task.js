chorus.models.SqlExecutionAndDownloadTask = chorus.models.WorkfileExecutionTask.extend({
    constructorName: "SqlExecutionAndDownloadTask",

    save: function() {
        var paramsToSave = this.underscoreKeys(_.pick(this.attributes, ['checkId', 'schemaId', 'sql', 'numOfRows']));
        paramsToSave['file_name'] = this.name();

        $.fileDownload(this.url(), {
            data: _.extend({
                download: true
            }, paramsToSave),
            httpMethod: "post",
            successCallback: _.bind(this.saved, this),
            failCallback: _.bind(this.saveFailed, this),
            cookieName: 'fileDownload_' + this.get('checkId')
        });
    },

    saved: function() {
        this.trigger("saved", this);
    },

    saveFailed: function(responseHtml) {
        var responseText = $(responseHtml).text();
        this.handleRequestFailure("saveFailed", {responseText: responseText});
    },

    cancel: function() {
        this._super("cancel");
        chorus.PageEvents.broadcast("file:executionCancelled");
    }
});
