chorus.dialogs.NameChorusView = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: "AssignChorusViewName",
    templateName: "name_chorus_view",
    title: t("dataset.name_chorus_view.title"),

    setup: function() {
        this.listenTo(this.model, "saved", this.chorusViewCreated);
        this.listenTo(this.model, "saveFailed", this.chorusViewFailed);
        this.listenTo(this.model, "validationFailed", this.chorusViewFailed);
        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input[name=objectName]"
        });
    },

    create: function(e) {
        e.preventDefault();

        this.model.set({ objectName: this.$("input[name=objectName]").val().trim() });
        this.$("button.submit").startLoading("actions.creating");
        this.model.save();
    },

    chorusViewCreated: function() {
        this.closeModal();
        chorus.router.navigate(this.model.showUrl());
    },

    chorusViewFailed: function() {
        this.$("button.submit").stopLoading();
    }
});
