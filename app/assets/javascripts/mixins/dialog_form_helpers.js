chorus.Mixins.DialogFormHelpers = {
    disableFormUnlessValid: function(options) {
        var events = {};
        var checkFn;
        if (options.checkInput) {
            checkFn = options.checkInput;
        } else {
            checkFn = _.bind(function() {
                var hasText = this.$(options.inputSelector).val().trim().length > 0;
                this.$("button.submit").prop("disabled", hasText ? false : "disabled");
            }, this);
        }

        events["keyup " + options.inputSelector] = checkFn;
        events["paste " + options.inputSelector] = checkFn;
        events["submit " + options.formSelector] = "create";
        this.events = _.extend(this.events || {}, events);
    }
};
