chorus.views.DatePicker = chorus.views.Base.extend({
    templateName: 'date_picker',

    setup: function () {
        this.date = this.options.date || new Date();
    },

    postRender: function () {
        var dateMatchers = {
            "%Y": this.$(".date input.year"),
            "%m": this.$(".date input.month"),
            "%d": this.$(".date input.day")
        };

        chorus.datePicker(dateMatchers, { disableBeforeToday: true });
    },

    getDate: function () {
        var date = new Date(
            parseInt(this.$(".date input.year").val(), 10),
            parseInt(this.$(".date input.month").val(), 10) - 1,
            parseInt(this.$(".date input.day").val(), 10)
        );
        return date;
    },

    disable: function () {
        var $date = this.$(".date input.year");
        datePickerController.disable($date.attr("id"));
    },

    enable: function () {
        var $date = this.$(".date input.year");
        datePickerController.enable($date.attr("id"));
    },

    additionalContext: function() {
        return {
            date: {
                month: this.date.getMonth() + 1,
                day: this.date.getDate(),
                year: this.date.getFullYear()
            }
        };
    }
});