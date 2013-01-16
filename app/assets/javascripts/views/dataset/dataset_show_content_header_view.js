chorus.views.DatasetShowContentHeader = chorus.views.ListHeaderView.extend({
    templateName: "dataset_show_content_header",
    additionalClass: 'show_page_header',

    subviews: {
        '.tag_box': 'tagBox'
    },

    setup: function() {
        this.tagBox = new chorus.views.TagBox({model: this.model});
        this.requiredResources.add(this.model);
    },

    additionalContext: function() {
        return {
            importFrequency: chorus.helpers.importFrequencyForModel(this.model),
            workspacesAssociated: this.model.workspacesAssociated(),
            tableauWorkbooks: this.model.tableauWorkbooks(),
            dataset: this.model.asWorkspaceDataset(),
            showLocation: this.options && this.options.showLocation,
            title: this.model.name(),
            imageUrl: this.model.iconUrl()
        };
    },

    postRender: function() {
        this._super('postRender', arguments);
        if (this.model.importFrequency && this.model.importFrequency()) {
            $(this.el).addClass('has_import');
        }
    }
});