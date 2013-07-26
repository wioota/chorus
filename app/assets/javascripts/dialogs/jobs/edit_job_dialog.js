chorus.dialogs.EditJob = chorus.dialogs.ConfigureJob.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: 'EditJob',
    title: t('job.dialog.edit.title'),
    message: 'job.dialog.edit.toast',
    submitTranslation: "job.dialog.edit.submit",

    setup: function () {
        this.model = this.job =  this.options.model;
        this.startDate = this.model.nextRunDate();
        this.endDate = this.model.endRunDate();

        this._super('setup');
    },

    postRender: function () {
        this._super("postRender");

        this.prePopulateFields();
        this.toggleSubmitDisabled();
    },

    setupDatePickers: function () {
        this.startDatePicker = new chorus.views.DatePicker({date: this.startDate, selector: 'start_date'});
        this.registerSubView(this.startDatePicker);

        this.endDatePicker = new chorus.views.DatePicker({date: this.endDate, selector: 'end_date'});
        this.registerSubView(this.endDatePicker);
    },

    populateExistingTime: function () {
        var times = this.model.nextRunTime();

        this.$('select.hour').val(times.hours);
        this.$('select.minute').val(times.minutes);
        this.$('select.meridiem').val(times.meridiem);
    },

    modelSaved: function () {
        chorus.toast(this.message);
        this.model.trigger('invalidated');
        this.closeModal();
    },

    prePopulateFields: function () {
        this.$('input.name').val(this.model.get('name'));
        this.$('input.end_date_enabled').prop("checked", this.model.get("endRun")).trigger("change");

        if (!this.model.runsOnDemand()) {
            this.$('input:radio#onDemand').prop("checked", false);
            this.$('input:radio#onSchedule').prop("checked", true).trigger("change");

            this.$('input.interval_value').val(this.model.get('intervalValue'));
            this.$('select.interval_unit').val(this.model.get('intervalUnit'));

            this.populateExistingTime();
        }
    }
});