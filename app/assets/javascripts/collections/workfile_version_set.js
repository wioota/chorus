chorus.collections.WorkfileVersionSet = chorus.collections.Base.extend({
    constructorName: "WorkfileVersionSet",
    urlTemplate:"workfiles/{{workfileId}}/versions",
    model:chorus.models.Workfile,
    comparator:function (model) {
        return -model.get("versionInfo").versionNum;
    },

    // TODO: don't mess with the id of all the models, but backbone is enforcing uniqueness
    _prepareModel: function () {
        var model = this._super('_prepareModel', arguments);
        model.id = model.id + "v" + model.get("versionInfo").versionNum;
        return model;
    }
});