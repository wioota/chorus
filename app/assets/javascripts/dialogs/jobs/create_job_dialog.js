chorus.dialogs.CreateJob = chorus.dialogs.Base.include(chorus.Mixins.DialogFormHelpers).extend({
    constructorName: 'CreateJob',
    templateName: 'create_job_dialog',
    title: t('create_job_dialog.title'),
    message: 'create_job_dialog.toast',

    subviews: {
        ".date": "datePicker"
    },

    events: {
        "change input:radio": 'toggleScheduleOptions'
    },

    makeModel: function () {
        this.workspace = this.options.workspace;
        this.model = new chorus.models.Job({ workspace: {id: this.workspace.id} });
    },

    setup: function () {
        this.datePicker = new chorus.views.DatePicker();
        this.registerSubView(this.datePicker);

        this.disableFormUnlessValid({
            formSelector: "form",
            inputSelector: "input",
            checkInput: _.bind(this.checkInput, this)
        });

        this.listenTo(this.model, "saved", this.modelSaved);
        this.toggleSubmitDisabled();
    },

    postRender: function () {
        _.defer(_.bind(function () {
            chorus.styleSelect(this.$("select"));
        }, this));
    },

    checkInput: function () {
        var name = this.$('input.name').val();
        if (!name) return false;

        if (this.isOnDemand()) {
            return name.length > 0;
        } else {
            return name.length > 0 && this.getIntervalValue().length > 0 &&
                this.datePicker.getDate().toString() !== "Invalid Date";
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
            nextRun: this.isOnDemand() ? null : this.buildDate().toUTCString()
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

    buildDate: function () {
        var date = this.datePicker.getDate();
        var hourBase = parseInt(this.$('select.hour').val(), 10);
        var hour = this.$('select.meridian').val() === "am" ? hourBase : hourBase + 12;
        date.setHours(hour);
        date.setMinutes(parseInt(this.$('select.minute').val(), 10));
        return date;
    },

    toggleScheduleOptions: function () {
        this.$('.interval_options').toggleClass('hidden', this.isOnDemand());
        this.toggleSubmitDisabled();
    },

    modelSaved: function () {
        chorus.toast(this.message);
        this.model.trigger('invalidated');
        this.closeModal();
    },

    additionalContext: function () {
        return {
          hours: _.range(1,12).map(function (digit) {
              return {value: digit};
          }),
          minutes: _.compact(_.range(0,60).map(function (digit) {
              if (digit % 5 === 0) return {
                  value: digit,
                  label: (digit - 9) > 0 ? digit : "0" + digit.toString()
              };
          }))
        };
    }
});