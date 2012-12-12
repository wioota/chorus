chorus.views.WorkfileHeader = chorus.views.Base.extend({
    templateName: "workfile_header",

    additionalContext:function () {
        return {
            iconUrl: this.model.iconUrl()
        };
    }
});
