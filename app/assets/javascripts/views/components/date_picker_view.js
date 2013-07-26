chorus.views.DatePicker = chorus.views.Base.extend({
    templateName: 'date_picker',

    setup: function () {
        this.date = this.options.date || new Date();
        this.selector = this.options.selector || "date";
    },

    postRender: function () {
        this.daySelector = this.$("." + this.selector + " input.day");
        this.daySelector.val(this.date.getDate());

        this.monthSelector = this.$("." + this.selector + " input.month");
        this.monthSelector.val(this.date.getMonth() + 1);

        this.yearSelector = this.$("." + this.selector + " input.year");
        this.yearSelector.val(this.date.getFullYear());


        var dateMatchers = {
            "%Y": this.yearSelector,
            "%m": this.monthSelector,
            "%d": this.daySelector
        };

        chorus.datePicker(dateMatchers, { disableBeforeToday: true });
    },

    getDate: function () {
        var date = new Date(
            parseInt(this.yearSelector.val(), 10),
            parseInt(this.monthSelector.val(), 10) - 1,
            parseInt(this.daySelector.val(), 10)
        );
        return date;
    },

    disable: function () {
        this.daySelector.prop("disabled", "disabled");
        this.monthSelector.prop("disabled", "disabled");
        this.yearSelector.prop("disabled", "disabled");
        datePickerController.disable(this.yearSelector.attr("id"));
    },

    enable: function () {
        this.daySelector.prop("disabled", false);
        this.monthSelector.prop("disabled", false);
        this.yearSelector.prop("disabled", false);
        datePickerController.enable(this.yearSelector.attr("id"));
    },

    additionalContext: function() {
        return {
            date: {
                month: this.date.getMonth() + 1,
                day: this.date.getDate(),
                year: this.date.getFullYear()
            },
            selector: this.selector
        };
    }
});