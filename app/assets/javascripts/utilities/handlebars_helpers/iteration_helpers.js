chorus.handlebarsHelpers.iteration = {
    // Usage: {{#keyValue obj}} Key: {{key}} // Value: {{value}} {{/keyValue}}
    //
    // Iterate over an object, setting 'key' and 'value' for each property in
    // the object.
    keyValue: function(obj, fn) {
        var buffer = "",
            key;

        for(key in obj) {
            if(obj.hasOwnProperty(key)) {
                buffer += fn({key: key, value: obj[key]});
            }
        }

        return buffer;
    },

    ifAll: function() {
        var args = _.toArray(arguments);
        var block = args.pop();
        if (block.length === 0) {
            throw "ifAll expects arguments";
        }
        if (_.all(args, function(arg) {
            return !!arg;
        })) {
            return block(this);
        } else {
            return block.inverse(this);
        }
    },

    ifAny: function() {
        var args = _.toArray(arguments);
        var block = args.pop();
        if (block.length === 0) {
            throw "ifAny expects arguments";
        }
        if (_.any(args, function(arg) {
            return !!arg;
        })) {
            return block(this);
        } else {
            return block.inverse(this);
        }
    },

    eachFunctionResult: function() {
        var args = _.toArray(arguments);
        var block = args.pop();
        var results = "";
        var attachments = args[0].apply(this);
        _.each(attachments, function(attachment) {
            results += block(attachment);
        });
        return results;
    }
};

_.each(chorus.handlebarsHelpers.iteration, function(helper, name) {
    Handlebars.registerHelper(name, helper);
});