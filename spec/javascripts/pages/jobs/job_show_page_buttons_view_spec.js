describe("chorus.views.JobShowPageButtons", function () {

    beforeEach(function () {
        this.job = backboneFixtures.job();
        this.view = new chorus.views.JobShowPageButtons({model: this.job});
        this.modalSpy = stubModals();
        this.view.render();
    });

    describe("clicking the 'Add Task' button", function () {
        itBehavesLike.aDialogLauncher('button.create_task', chorus.dialogs.CreateJobTask);
    });

});