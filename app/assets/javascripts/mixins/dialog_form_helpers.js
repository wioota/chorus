chorus.Mixins.DialogFormHelpers = {
    disableFormUnlessValid: function(options) {
        var events = {};
        var checkFn;
        if (options.checkInput) {
            checkFn = options.checkInput;
        } else {
            checkFn = _.bind(function() {
                return this.$(options.inputSelector).val().trim().length > 0;
            }, this);
        }

        this.toggleSubmitDisabled = _.bind(function() {
            this.$("button.submit").prop("disabled", checkFn() ? false : "disabled");
        }, this);

        events["keyup " + options.inputSelector] = this.toggleSubmitDisabled;
        events["paste " + options.inputSelector] = this.toggleSubmitDisabled;
        events["submit " + options.formSelector] = "onFormSubmit";
        this.events = _.extend(this.events || {}, events);
    },

    onFormSubmit: function(e) {
        e.preventDefault();
        e.stopPropagation();

        this.create(e);
        return false;
    }
};
