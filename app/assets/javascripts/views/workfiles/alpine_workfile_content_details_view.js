chorus.views.AlpineWorkfileContentDetails = chorus.views.WorkfileContentDetails.extend({
    templateName: "alpine_workfile_content_details",

    additionalContext: function () {
        return  { alpineUrl: this.model.runUrl() };
    }
});
