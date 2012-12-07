chorus.models.Insight = chorus.models.Note.extend({
    constructorName: "Insight",
    parameterWrapper: "note",

    urlTemplate:function (options) {
        var action = this.get('action');

        if (options && options.isFile) {
            return "notes/{{id}}/attachments"
        } else if (action == "create") {
            return "insights";
        } else {
            return "notes/{{id}}";
        }
    },
    
    initialize: function() {
        this._super('initialize');
        this.set({ isInsight: true });
    },

    declareValidations:function (newAttrs) {
        if (!newAttrs['promote']) {
            this.require('body', newAttrs);
        }
    }
});
