chorus.dialogs.SandboxNew = chorus.dialogs.Base.extend({
    constructorName: "SandboxNew",

    templateName: "sandbox_new",
    title: t("sandbox.new_dialog.title"),

    persistent: true,

    events: {
        "click input[value='within_instance']": "showInstanceMode",
        "click input[value='as_standalone']": "showStandaloneMode",
        "click button.submit": "save"
    },

    subviews: {
        "form > .instance_mode": "instanceMode",
        "form > .standalone_mode": "standaloneMode"
    },

    setup: function() {
        this.instanceMode = new chorus.views.SchemaPicker({allowCreate: true});
        this.instanceMode.bind("change", this.enableOrDisableSaveButton, this);
        this.bindings.add(this.instanceMode, "error", this.showErrors);
        this.bindings.add(this.instanceMode, "clearErrors", this.clearErrors);

        this.workspace.fetch();

        this.requiredResources.add(this.workspace);
        this.requiredResources.add(chorus.models.Config.instance());

        this.standaloneMode = new chorus.views.SandboxNewStandaloneMode({addingSandbox: true});
        this.activeForm = this.instanceMode;

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
        this.model.maximumSize = chorus.models.Config.instance().get("provisionMaxSizeInGB");
    },

    save: function(e) {
        this.$("button.submit").startLoading("sandbox.adding_sandbox");

        var sandboxId  = this.activeForm.schemaId();
        var schemaName = sandboxId ? undefined : this.activeForm.fieldValues().schemaName;
        var databaseId = this.activeForm.fieldValues().database;
        var databaseName = databaseId ? undefined : this.activeForm.fieldValues().databaseName;
        var instanceId = this.activeForm.fieldValues().instance;

        this.model.set({
            schemaId: sandboxId,
            schemaName: schemaName,
            databaseId: databaseId,
            databaseName: databaseName,
            instanceId: instanceId
        });

        this.model.save();
    },

    saved: function() {
        if (this.activeForm != this.standaloneMode) {
            chorus.toast("sandbox.create.toast");
        }
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
    },

    showInstanceMode: function() {
        this.$(".instance_mode").removeClass("hidden");
        this.$(".standalone_mode").addClass("hidden");

        this.activeForm = this.instanceMode;
        this.enableOrDisableSaveButton(this.instanceMode.ready())
    },

    showStandaloneMode: function() {
        this.$(".instance_mode").addClass("hidden");
        this.$(".standalone_mode").removeClass("hidden");

        this.activeForm = this.standaloneMode;
        this.enableOrDisableSaveButton(true);
    }
});
