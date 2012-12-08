chorus.models.InsightCount = chorus.models.Base.extend({
    constructorName: 'InsightCount',
    parameterWrapper : 'insight'
}, {
    count: function(options) {
        options || (options = {});
        var count = new chorus.models.Base();
        count.urlTemplate = "insights/count";
        count.urlParams = options.urlParams;
        return count;
    }
});
