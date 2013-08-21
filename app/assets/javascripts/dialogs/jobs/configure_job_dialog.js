chorus.dialogs.ConfigureJob = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    templateName: 'configure_job_dialog',
    title: function () {
        return this.model.isNew() ? t('job.dialog.title') : t('job.dialog.edit.title');
    },
    message: function () {
        return this.model.isNew() ? 'job.dialog.toast' : 'job.dialog.edit.toast';
    },
    submitTranslation: function () {
        return this.model.isNew() ? "job.dialog.submit" : "job.dialog.edit.submit";
    },

    subviews: {
        ".start_date": "startDatePicker",
        ".end_date": "endDatePicker"
    },

    events: {
        "change input:radio": 'toggleScheduleOptions',
        "change .end_date_enabled": 'toggleEndRunDateWidget'
    },

    makeModel: function () {
        this.creating = !this.model;
        this.model = this.model || new chorus.models.Job({ workspace: {id: this.options.workspace.id}, intervalUnit: 'on_demand' });
    },

    modelSaved: function () {
        chorus.toast(this.message());
        this.model.trigger('invalidated');
        this.closeModal();

        if (this.creating) {
            chorus.router.navigate(this.model.showUrl());
        }
    },

    setup: function () {
        this.setupDatePickers();

        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input",
            checkInput: _.bind(this.checkInput, this)
        });

        this.listenTo(this.model, "saved", this.modelSaved);
        this.listenTo(this.model, 'saveFailed', this.saveFailed);
        this.toggleSubmitDisabled();
    },

    setupDatePickers: function () {
        this.startDatePicker = new chorus.views.DatePicker({date: this.model.nextRunDate(), selector: 'start_date'});
        this.registerSubView(this.startDatePicker);

        this.endDatePicker = new chorus.views.DatePicker({date: this.model.endRunDate(),selector: 'end_date'});
        this.registerSubView(this.endDatePicker);
    },

    postRender: function () {
        _.defer(_.bind(function () {
            chorus.styleSelect(this.$("select"));
        }, this));

        this.$('.end_date').prop("disabled", "disabled");
        this.endDatePicker.disable();

        this.populateSelectors();
        this.toggleEndRunDateWidget();
        this.toggleSubmitDisabled();
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
        this.model.save(this.fieldValues(), {wait: true, unprocessableEntity: $.noop});
    },

    fieldValues: function () {
        return {
            name: this.$('input.name').val(),
            intervalUnit: this.getIntervalUnit(),
            intervalValue: this.getIntervalValue(),
            nextRun: this.isOnDemand() ? "invalid" : this.buildStartDate().forceZone(0).format(),
            endRun: this.isOnDemand() || !this.endDateEnabled() ? "invalid" : this.buildEndDate().toISOString(),
            timeZone: this.$('select.time_zone').val(),
            successNotify: this.$('[name=success_notify]:checked').val(),
            failureNotify: this.$('[name=failure_notify]:checked').val()
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

    populateSelectors: function () {
        var runDate = this.model.nextRunDate();

        var hoursBase = runDate.hours();
        var meridiem = hoursBase - 11 > 0 ? "pm" : "am";
        var hours = meridiem === "pm" ? hoursBase - 12 : hoursBase;
        hours = hours === 0 ? 12 : hours;
        var minutes = runDate.minutes();
        var zone = this.model.get('timeZone') || RailsTimeZone.to(jstz.determine().name());

        this.$('select.interval_unit').val(this.model.get('intervalUnit'));

        this.$('select.hour').val(hours);
        this.$('select.minute').val(minutes);
        this.$('select.meridiem').val(meridiem);
        this.$('select.time_zone').val(zone);
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
            submitTranslation: this.submitTranslation(),
            runsOnDemand: this.model.runsOnDemand(),
            successNotifyEverybody: this.model.get('successNotify') === 'everybody',
            successNotifySelected: this.model.get('successNotify') === 'selected',
            successNotifyNobody: this.model.get('successNotify') === 'nobody'  || !this.model.get('successNotify'),
            failureNotifyEverybody: this.model.get('failureNotify') === 'everybody',
            failureNotifySelected: this.model.get('failureNotify') === 'selected',
            failureNotifyNobody: this.model.get('failureNotify') === 'nobody' || !this.model.get('failureNotify')

        };
    }
});
