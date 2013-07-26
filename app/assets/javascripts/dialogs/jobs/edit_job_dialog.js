chorus.dialogs.EditJob = chorus.dialogs.ConfigureJob.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: 'EditJob',
    title: t('job.dialog.edit.title'),
    message: 'job.dialog.edit.toast',
    submitTranslation: "job.dialog.edit.submit",

    setup: function () {
        this.model = this.job =  this.options.model;
        var startDate = this.model.get("nextRun");
        this.startDate = startDate ? new Date(startDate) : new Date();

        var endDate = this.model.get("endRun");
        this.endDate = endDate ? new Date(endDate) : new Date();
        this._super('setup');
    },

    postRender: function () {
        this._super("postRender");

        this.$('input.name').val(this.model.get('name'));
        this.$('input.end_date_enabled').prop("checked", this.model.get("endRun")).trigger("change");

        if(!this.model.runsOnDemand()) {
            this.$('input:radio#onDemand').prop("checked", false);
            this.$('input:radio#onSchedule').prop("checked", true).trigger("change");

            this.$('input.interval_value').val(this.model.get('intervalValue'));
            this.$('select.interval_unit').val(this.model.get('intervalUnit'));

            this.populateExistingTime();
        }
        this.toggleSubmitDisabled();
    },

    setupDatePickers: function () {
        this.startDatePicker = new chorus.views.DatePicker({date: this.startDate, selector: 'start_date'});
        this.registerSubView(this.startDatePicker);

        this.endDatePicker = new chorus.views.DatePicker({date: this.endDate, selector: 'end_date'});
        this.registerSubView(this.endDatePicker);
    },

    populateExistingTime: function () {
        var hoursBase = this.startDate.getHours();
        var meridian = hoursBase - 11 > 0 ? "pm" : "am";
        var hours = meridian === "pm" ? hoursBase - 12 : hours;
        hours = hours === 0 ? 12 : hours;

        this.$('select.hour').val(hours);
        this.$('select.minute').val(Math.floor(this.startDate.getMinutes() / 5) * 5);
        this.$('select.meridian').val(meridian);
    },

    modelSaved: function () {
        chorus.toast(this.message);
        this.model.trigger('invalidated');
        this.closeModal();
    }
});