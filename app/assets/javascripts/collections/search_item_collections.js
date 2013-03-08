(function() {
    chorus.collections.Search = {};

    var searchCollectionMixins = {
        initialize: function(models, options) {
            this._super("initialize", arguments);
            this.search = options.search;
        },

        refreshFromSearch: function() {
            var entityJson = this.search.get(this.searchKey);
            this.pagination = {
                page: this.search.currentPageNumber(),
                total: this.search.numPages(entityJson.numFound),
                records: entityJson.numFound
            };
            this.reset(entityJson.results);
        },

        fetchPage: function(pageNumber, options) {
            this.search.set({ page: pageNumber });
            this.search.fetch({ success: _.bind(this.refreshFromSearch, this) });
        }
    };

    var constructorMap = {
        workfile: chorus.models.DynamicWorkfile,
        dataset: chorus.models.DynamicDataset,
        workspace: chorus.models.Workspace,
        attachment: chorus.models.Attachment
    };

    chorus.collections.Search.WorkspaceItemSet = chorus.collections.Base.include(
        searchCollectionMixins
    ).extend({
        constructorName: "WorkspaceItemSet",
        searchKey: "thisWorkspace",
        model: function(modelJson, options) {
            var constructor = constructorMap[modelJson.entityType];
            return new constructor(modelJson, options);
        },
        // TODO: don't mess with the id of all the models, but backbone is enforcing uniqueness
        _prepareModel: function () {
            var model = this._super('_prepareModel', arguments);
            model.id = model.id + model.constructorName;
            return model;
        }
    });

    chorus.collections.Search.HdfsEntrySet = chorus.collections.HdfsEntrySet.include(
        searchCollectionMixins
    ).extend({
        searchKey: "hdfsEntries"
    });

    chorus.collections.Search.InstanceSet = chorus.collections.GpdbDataSourceSet.include(
        searchCollectionMixins
    ).extend({
        searchKey: "instances",
        model: chorus.models.DynamicInstance,
        // TODO: don't mess with the id of all the models, but backbone is enforcing uniqueness
        _prepareModel: function () {
            var model = this._super('_prepareModel', arguments);
            model.id = model.id + model.constructorName;
            return model;
        }
    });

    chorus.collections.Search.DatasetSet = chorus.collections.SchemaDatasetSet.include(
        searchCollectionMixins
    ).extend({
        searchKey: "datasets"
    });

    chorus.collections.Search.UserSet = chorus.collections.UserSet.include(
        searchCollectionMixins
    ).extend({
        searchKey: "users"
    });

    chorus.collections.Search.WorkspaceSet = chorus.collections.WorkspaceSet.include(
        searchCollectionMixins
    ).extend({
        searchKey: "workspaces"
    });

    chorus.collections.Search.WorkfileSet = chorus.collections.WorkfileSet.include(
        searchCollectionMixins
    ).extend({
        searchKey: "workfiles"
    });

    chorus.collections.Search.AttachmentSet = chorus.collections.AttachmentSet.include(
        searchCollectionMixins
    ).extend({
        searchKey: "attachment"
    });
})();
