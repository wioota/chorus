chorus.dialogs.WorkFlowNew = chorus.dialogs.Base.extend({
    templateName: "work_flow_new",
    title: t("work_flows.new_dialog.title"),

    events: {
        "keyup input[name=fileName]": "checkInput",
        "paste input[name=fileName]": "checkInput",
        "submit form": "create"
    },

    setup: function() {
        this.model = this.resource = new chorus.models.Workfile();
    },

    postRender: function() {
        this.checkInput();
    },

    getFileName: function() {
        return this.$("input[name=fileName]").val().trim();
    },

    fileNameIsValid: function() {
        return this.getFileName().length > 0;
    },

    disableSubmit: function(hasText) {
        this.$("button.submit").prop("disabled", hasText ? false : "disabled");
    },

    checkInput: function() {
        var hasText = this.fileNameIsValid();
        this.disableSubmit(hasText);
    },

    create: function create(e) {
        e.preventDefault();

        var fileName = this.getFileName();

        this.resource.set({
            fileName: fileName
        });

        this.$("button.submit").startLoading("actions.adding");
        this.resource.save({source: "empty"});
    }
});
