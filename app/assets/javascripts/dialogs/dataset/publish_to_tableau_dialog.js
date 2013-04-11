chorus.dialogs.PublishToTableau = chorus.dialogs.Base.extend({
    constructorName: "PublishTableau",

    templateName:"publish_to_tableau_dialog",
    title: 'Publish to Tableau',

    events:{
        "click button.submit": "publishToTableau"
    },

    setup: function() {
        this.dataset = this.options.dataset;
        this.listenTo(this.model, "saved", this.saveSuccess);
        this.listenTo(this.model, "saveFailed", this.saveFailed);
        this.listenTo(this.model, "validationFailed", this.saveFailed);
    },

    publishToTableau: function() {
        var attrs = {};

        _.each(["name", "tableau_username", "tableau_password"], function(name) {
            var input = this.$("input[name=" + name + "]");
            if (input.length) {
                attrs[name] = input.val().trim();
            }
        }, this);
        attrs['createWorkFile'] = this.$("input[name='create_work_file']").is(':checked');
        this.model.set(attrs, {silent: true});
        this.$("button.submit").startLoading('actions.publishing');
        this.$("button.cancel").prop("disabled", true);
        this.model.save();
    },

    saveSuccess: function() {
        chorus.toast("tableau.published",
            {
                objectType: this.model.get('dataset').humanType(),
                objectName: this.model.get('dataset').shortName(20),
                name: this.model.shortName(20)
            });
        this.closeModal();
        this.dataset.tableauWorkbooks().add(this.model);
        this.dataset.trigger("change");
    },

    saveFailed: function() {
        this.$("button.submit").stopLoading();
        this.$("button.cancel").prop("disabled", false);
    }
});
