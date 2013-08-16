chorus.handlebarsHelpers.time = {
    displayAbbreviatedTimestamp: function(timestamp) {
        var date = Date.parseFromApi(timestamp);
        return date ? date.toString("MMMM d") : "";
    },

    relativeTimestamp: function(timestamp) {
        var date = Date.parseFromApi(timestamp);
        return date ? date.toRelativeTime(60000) : "";
    },

    displayTimestamp: function (timestamp) {
        var date = moment(timestamp);
        return (timestamp && date.isValid()) ? date.format('MMMM Do YYYY, h:mm a') : "";
    }
};

_.each(chorus.handlebarsHelpers.time, function(helper, name) {
    Handlebars.registerHelper(name, helper);
});