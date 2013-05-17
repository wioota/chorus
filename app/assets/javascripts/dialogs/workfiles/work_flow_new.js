chorus.dialogs.WorkFlowNew = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    templateName: "work_flow_new",
    title: t("work_flows.new_dialog.title"),

    setup: function() {
        this.model = this.resource = new chorus.models.Workfile();
        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input[name=fileName]"
        });
    },

    getFileName: function() {
        return this.$("input[name=fileName]").val().trim();
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
