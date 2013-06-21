chorus.dialogs.WorkFlowNewForHdfsEntryList = chorus.dialogs.WorkFlowNewBase.extend({
    checkInput: function() {
        return this.getFileName().trim().length > 0;
    },

    resourceAttributes: function () {
        return {
            fileName: this.getFileName(),
            hdfsEntryIds: this.collection.pluck('id')
        };
    }
});