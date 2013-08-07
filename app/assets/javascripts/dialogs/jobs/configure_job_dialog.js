chorus.dialogs.ConfigureJob = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    templateName: 'create_job_dialog',
    title: t('job.dialog.title'),
    message: 'job.dialog.toast',
    submitTranslation: "job.dialog.submit",

    subviews: {
        ".start_date": "startDatePicker",
        ".end_date": "endDatePicker"
    },

    events: {
        "change input:radio": 'toggleScheduleOptions',
        "change .end_date_enabled": 'toggleEndRunDateWidget'
    },

    setup: function () {
        this.setupDatePickers();

        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input",
            checkInput: _.bind(this.checkInput, this)
        });

        this.listenTo(this.model, "saved", this.modelSaved);
        this.toggleSubmitDisabled();
    },

    setupDatePickers: function () {
        this.startDatePicker = new chorus.views.DatePicker({selector: 'start_date'});
        this.registerSubView(this.startDatePicker);

        this.endDatePicker = new chorus.views.DatePicker({selector: 'end_date'});
        this.registerSubView(this.endDatePicker);
    },

    postRender: function () {
        _.defer(_.bind(function () {
            chorus.styleSelect(this.$("select"));
        }, this));

        this.$('.end_date').prop("disabled", "disabled");
        this.endDatePicker.disable();
    },

    checkInput: function () {
        var name = this.$('input.name').val();
        if (!name) return false;

        if (this.isOnDemand()) {
            return name.length > 0;
        } else {
            return name.length > 0 && this.getIntervalValue().length > 0 &&
                this.startDatePicker.getDate().isValid() &&
                (!this.endDateEnabled() || this.endDatePicker.getDate().isValid());
        }
    },

    create: function () {
        this.$("button.submit").startLoading('actions.saving');
        this.model.save(this.fieldValues(), {wait: true});
    },

    fieldValues: function () {
        return {
            name: this.$('input.name').val(),
            intervalUnit: this.getIntervalUnit(),
            intervalValue: this.getIntervalValue(),
            nextRun: this.isOnDemand() ? "invalid" : this.buildStartDate().forceZone(0).format(),
            endRun: this.isOnDemand() || !this.endDateEnabled() ? "invalid" : this.buildEndDate().toISOString(),
            timeZone: this.$('select.time_zone').val()
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

    buildStartDate: function () {
        var date = this.startDatePicker.getDate();
        var hourBase = parseInt(this.$('select.hour').val(), 10) % 12;
        var hour = this.$('select.meridiem').val() === "am" ? hourBase : hourBase + 12;
        date.hour(hour);
        date.minute(this.$('select.minute').val());
        return date;
    },

    buildEndDate: function () {
        return this.endDatePicker.getDate();
    },

    toggleScheduleOptions: function () {
        this.$('.interval_options').toggleClass('hidden', this.isOnDemand());
        this.toggleSubmitDisabled();
    },

    toggleEndRunDateWidget: function () {
        this.endDateEnabled() ? this.endDatePicker.enable() : this.endDatePicker.disable();
    },

    endDateEnabled: function () {
        return this.$(".end_date_enabled").prop("checked");
    },

    additionalContext: function () {
        return {
            hours: _.range(1,13).map(function (digit) {
                return {value: digit};
            }),
            minutes: _.range(0,60).map(function (digit) {
                return {
                    value: digit,
                    label: digit > 9 ? digit : "0" + digit.toString()
                };
            }),
            submitTranslation: this.submitTranslation
        };
    }

});
