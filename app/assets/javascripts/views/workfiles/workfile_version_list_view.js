chorus.views.WorkfileVersionList = chorus.views.Base.extend({
    constructorName: "WorkfileVersionListView",
    templateName: "workfile_version_list",
    tagName: "ul",

    collectionModelContext: function(workfileVersion) {
        var author = workfileVersion.modifier();

        var versionInfo = workfileVersion.get("versionInfo");
        var date = Date.parseFromApi(versionInfo && versionInfo.updatedAt);
        var formattedDate = date && date.toString("MMMM dd, yyyy");
        var workspace = workfileVersion.workspace();
        return {
            canDelete: workspace.canUpdate() && workspace.isActive(),
            versionId: workfileVersion.get("versionInfo").id,
            versionNumber: workfileVersion.get("versionInfo").versionNum,
            authorName: author.displayName(),
            formattedDate: formattedDate,
            showUrl: workfileVersion.showUrl()
        }
    }
});
