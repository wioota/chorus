describe("chorus.views.JobQuickstart", function () {
    beforeEach(function () {
        this.page = new chorus.views.JobQuickstart({model: backboneFixtures.job({tasks: []})});
        this.modalSpy = stubModals();
        this.page.render();
    });

    itBehavesLike.aDialogLauncher('a.new_import_source_data.dialog', chorus.dialogs.ConfigureImportSourceDataTask);
    itBehavesLike.aDialogLauncher('a.new_run_work_flow.dialog', chorus.dialogs.ConfigureWorkfileTask);
    itBehavesLike.aDialogLauncher('a.new_run_sql.dialog', chorus.dialogs.ConfigureWorkfileTask);
});
