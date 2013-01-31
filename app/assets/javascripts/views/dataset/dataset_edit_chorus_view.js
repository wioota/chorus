chorus.views.DatasetEditChorusView = chorus.views.Base.extend({
    templateName: "dataset_edit_chorus_view",
    constructorName: "DatasetEditChorusView",

    subviews: {
        ".editor": "editor"
    },

    setup: function() {
        this.adaptModelForCodeEditor();
        this.editor = new chorus.views.CodeEditorView({
            model: this.model,
            readOnly: false,
            mode: "text/x-sql",
            extraKeys: {}
        });

        this.subscriptions.push(chorus.PageEvents.subscribe("dataset:saveEdit", this.saveModel, this));
        this.subscriptions.push(chorus.PageEvents.subscribe("dataset:cancelEdit", this.cancelEdit, this));
        this.model.initialQuery = this.model.get("query");
        this.bindings.add(this.model, "saved", this.navigateToChorusViewShowPage);
        this.bindings.add(this.editor, 'blur', this.updateQueryInModel);
    },

    updateQueryInModel: function() {
        this.model.set({query: this.editor.getValue()}, {silent: true});
    },

    saveModel: function() {
        // Don't want to navigate away on invalid model
        chorus.page.bindings.remove(this.model, "unprocessableEntity");

        var query = this.editor.getValue();

        this.model.set({query: query}, {silent: true});
        this.model.save(undefined, {silent: true});
    },

    cancelEdit: function() {
        delete this.model.serverErrors;
    },

    navigateToChorusViewShowPage: function() {
        chorus.router.navigate( this.model.showUrl());
    },

    adaptModelForCodeEditor: function () {
        this.model.content = function() { return this.get("query"); };
    }
});
