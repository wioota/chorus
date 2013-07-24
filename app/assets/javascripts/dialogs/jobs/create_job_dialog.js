chorus.dialogs.CreateJob = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: 'CreateJob',
    templateName: 'create_job_dialog',
    title: t('create_job_dialog.title'),

    events: {
        "change input:radio": 'toggleIntervalOptions'
    },
    
    makeModel: function () {
        this.workspace = this.options.workspace;
        this.model = new chorus.models.Job({ workspace: {id: this.workspace.id} });
    },

    setup: function () {
        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input",
            checkInput: _.bind(this.checkInput, this)
        });
        this.toggleSubmitDisabled();
    },

    postRender: function () {
        _.defer(_.bind(function() {
            chorus.styleSelect(this.$("select"));
        }, this));
    },

    checkInput: function () {
        // todo: form logic
        return true;
    },

    create: function () {
        this.$("button.submit").startLoading('actions.saving');
        this.model.save(this.fieldValues(), {wait: true});
    },

    fieldValues: function () {
        return {
            name: this.$('input.name').val(),
            intervalUnit: this.getIntervalUnit(),
            intervalValue: this.getIntervalValue()
        };
    },

    isOnDemand: function () {
        return this.$('input:radio[name=jobType]:checked').val() === 'on_demand';
    },

    getIntervalUnit: function () {
        return this.isOnDemand() ? 'on_demand' : this.$('select.interval_unit').val();
    },

    getIntervalValue: function () {
        return this.isOnDemand() ? '0' : this.$('input.interval_value').val();
    },

    toggleIntervalOptions: function () {
        this.$('.interval_options').prop('disabled', this.isOnDemand());
    }
});