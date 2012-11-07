chorus.Mixins.ServerErrors = {
   serverErrorMessages: function() {
        var output = [];
        if (!this.serverErrors) { return output; }

        var that = this;
        if (this.serverErrors.fields) {
            _.each(this.serverErrors.fields, function(errors, field) {
                _.each(errors, function(context, error) {
                    var fullKey = "field_error." + field + "." + error,
                        genericKey = "field_error." + error,
                        message;

                    var message = that.translateError(fullKey, context);

                    if(!message) {
                        context.field = _.humanize(field);
                        message = that.translateError(genericKey, context);
                    }

                    output.push(message)
                })
            })
        } else if (this.serverErrors.record) {
            var key = "record_error." + this.serverErrors.record;

            output = [this.translateError(key) || this.serverErrors.record];
        }

        return output;
    },

    serverErrorMessage: function() {
        return this.serverErrorMessages().join("\n");
    },

    translateError: function(key, context) {
        if (I18n.lookup(key)) {
            return t(key, context)
        }
    }
};
