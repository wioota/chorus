chorus.dialogs.EditJob = chorus.dialogs.ConfigureJob.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: 'EditJob',
    title: t('job.dialog.edit.title'),
    message: 'job.dialog.edit.toast',
    submitTranslation: "job.dialog.edit.submit",

    setup: function () {
        this.model = this.job = this.options.model;
        this.startDate = this.model.nextRunDate();
        this.endDate = this.model.endRunDate();

        this._super('setup');
    },

    postRender: function () {
        this._super("postRender");

        this.toggleSubmitDisabled();
    },

    setupDatePickers: function () {
        this.startDatePicker = new chorus.views.DatePicker({date: this.startDate, selector: 'start_date'});
        this.registerSubView(this.startDatePicker);

        this.endDatePicker = new chorus.views.DatePicker({date: this.endDate, selector: 'end_date'});
        this.registerSubView(this.endDatePicker);
    },

    modelSaved: function () {
        chorus.toast(this.message);
        this.model.trigger('invalidated');
        this.closeModal();
    }
});