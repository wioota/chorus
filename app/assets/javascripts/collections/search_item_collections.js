;(function() {
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
        workfile: chorus.models.Workfile,
        dataset: chorus.models.DynamicDataset,
        chorusView: chorus.models.DynamicDataset,
        workspace: chorus.models.Workspace,
        attachment: chorus.models.Artifact
    };

    chorus.collections.Search.WorkspaceItemSet = chorus.collections.Base.include(
        searchCollectionMixins
    ).extend({
        model: function(modelJson, options) {
            var constructor = constructorMap[modelJson.entityType];
            return new constructor(modelJson, options);
        },

        searchKey: "thisWorkspace"
    });

    chorus.collections.Search.HdfsEntrySet = chorus.collections.HdfsEntrySet.include(
        searchCollectionMixins
    ).extend({
        searchKey: "hdfs"
    });

    chorus.collections.Search.InstanceSet = chorus.collections.InstanceSet.include(
        searchCollectionMixins
    ).extend({
        searchKey: "instances"
    });

    chorus.collections.Search.DynamicDatasetSet = chorus.collections.DynamicDatasetSet.include(
        searchCollectionMixins
    ).extend({
        searchKey: "dataset"
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
        searchKey: "workfile"
    });

    chorus.collections.Search.ArtifactSet = chorus.collections.ArtifactSet.include(
        searchCollectionMixins
    ).extend({
        searchKey: "attachment"
    });
})();
