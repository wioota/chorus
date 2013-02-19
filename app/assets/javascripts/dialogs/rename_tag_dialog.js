chorus.dialogs.RenameTag = chorus.dialogs.Base.extend({
    constructorName: "RenameTagDialog",
    templateName: "rename_tag",
    title: t("rename_tag.title"),

    events: {
        "submit form" : "submit",
        "keyup input": "checkInput"
    },

    setup: function() {
        this.bindings.add(this.model, "saveFailed", this.saveFailed);
    },

    postRender: function() {
        this.input = this.$(".rename_tag_input");
    },

    newAttributes: function() {
        var value = this.input.val().trim();
        return _.extend(_.clone(this.model.attributes), {name: value});
    },

    submit: function(e) {
        e.preventDefault();
        this.model.save(this.newAttributes(), {silent: true});
    },

    saveFailed: function() {
        this.showErrors();
    },

    checkInput : function() {
        this.clearErrors();
        var newAttributes = this.newAttributes();
        var valid = this.model.performValidation(newAttributes);
        if (!valid) {
            this.markInputAsInvalid(this.input, this.model.errors.name, true);
        }
        var disabled = (newAttributes.name === this.model.name()) || !valid;
        this.$("button[type=submit]").prop("disabled", disabled);
    }
});