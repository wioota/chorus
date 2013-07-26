chorus.dialogs.CreateJob = chorus.dialogs.ConfigureJob.extend({
    constructorName: 'CreateJob',

    makeModel: function () {
        this.workspace = this.options.workspace;
        this.model = new chorus.models.Job({ workspace: {id: this.workspace.id} });
    },

    modelSaved: function () {
        chorus.toast(this.message);
        this.model.trigger('invalidated');
        this.closeModal();
        chorus.router.navigate(this.model.showUrl());
    }
});