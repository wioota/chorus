describe("chorus.views.ProjectStatusView", function() {
    beforeEach(function() {
        this.modalSpy = stubModals();
        this.model = new chorus.models.Workspace({ id : 4 });
        this.model.fetch();
        this.view = new chorus.views.ProjectStatus({ model : this.model });
        this.view.render();
    });

    itBehavesLike.aDialogLauncher("a.edit_project_status", chorus.dialogs.EditProjectStatus);
});
