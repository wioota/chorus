chorus.alerts.WorkfileDraft = chorus.alerts.Confirm.extend({
    constructorName: "WorkfileDraft",
    additionalClass: "warning",

    text: t("workfile.alert.text"),
    title: t("workfile.alert.title"),
    ok: t("workfile.alert.open_draft"),
    secondaryButton: t("workfile.alert.latest_version"),
    cancel: "",

    events: _.extend({
        "click button.secondaryButton": "useSavedButton"
    }, this.events),

    // open draft version
    confirmAlert: function () {

        var draft = new chorus.models.Draft({workspaceId:this.model.workspace().id, workfileId:this.model.get("id")});
        this.listenTo(draft, "change", function (draft) {
            this.closeModal();
            this.model.isDraft = true;
            this.model.content(draft.get("content"));
        });

        draft.fetch();
    },

    // open saved version
    useSavedButton: function () {

        var draft = new chorus.models.Draft({workspaceId:this.model.workspace().id, workfileId:this.model.get("id"), id:"Dummy"});

        this.listenTo(draft, "change", function () {
            draft.destroy();
        });

        this.listenTo(draft, "destroy", function () {
            this.closeModal();
            this.model.set({ hasDraft:false });
        });

        draft.fetch();
    },

     cancelAlert: function () {
        this.closeModal();
        window.history.back();
    },
   
});
