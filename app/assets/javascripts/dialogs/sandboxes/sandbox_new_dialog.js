chorus.dialogs.SandboxNew = chorus.dialogs.Base.extend({
    constructorName: "SandboxNew",

    templateName: "sandbox_new",
    title: t("sandbox.new_dialog.title"),

    persistent: true,

    events: {
        "click button.submit": "save"
    },

    subviews: {
        "form > .instance_mode": "schemaPicker"
    },

    setup: function() {
        this.schemaPicker = new chorus.views.SchemaPicker({allowCreate: true});
        this.bindings.add(this.schemaPicker, "change", this.enableOrDisableSaveButton);
        this.bindings.add(this.schemaPicker, "error", this.showErrors);
        this.bindings.add(this.schemaPicker, "clearErrors", this.clearErrors);

        this.workspace.fetch();

        this.requiredResources.add(this.workspace);
        this.requiredResources.add(chorus.models.Config.instance());

        this.bindings.add(this.model, "saved", this.saved);
        this.bindings.add(this.model, "saveFailed", this.saveFailed);
        this.bindings.add(this.model, "validationFailed", this.saveFailed);
    },

    makeModel: function() {
        this._super("makeModel", arguments);
        var workspaceId = this.options.workspaceId;
        this.workspace = new chorus.models.Workspace({id : workspaceId});
        this.model = new chorus.models.Sandbox({ workspaceId: workspaceId });
    },

    resourcesLoaded: function() {
    },

    save: function(e) {
        this.$("button.submit").startLoading("sandbox.adding_sandbox");

        var sandboxId  = this.schemaPicker.schemaId();
        var schemaName = sandboxId ? undefined : this.schemaPicker.fieldValues().schemaName;
        var databaseId = this.schemaPicker.fieldValues().database;
        var databaseName = databaseId ? undefined : this.schemaPicker.fieldValues().databaseName;
        var dataSourceId = this.schemaPicker.fieldValues().instance;

        this.model.set({
            schemaId: sandboxId,
            schemaName: schemaName,
            databaseId: databaseId,
            databaseName: databaseName,
            dataSourceId: dataSourceId
        });

        this.model.save();
    },

    saved: function() {
        chorus.toast("sandbox.create.toast");
        if (!this.options.noReload) {
            chorus.router.reload();
        }
        this.closeModal();
    },

    saveFailed: function() {
        this.$("button.submit").stopLoading();
        this.showErrors(this.model);
    },

    enableOrDisableSaveButton: function(schemaVal) {
        this.$("button.submit").prop("disabled", !schemaVal);
    }
});
