describe("chorus.dialogs.HdfsWorkFlowWorkspacePicker", function() {
    beforeEach(function() {
        this.hdfsEntries = {fake: 'HdfsEntrySet'};
        this.modalSpy = stubModals();
        this.dialog = new chorus.dialogs.HdfsWorkFlowWorkspacePicker({hdfsEntries: this.hdfsEntries});
        this.dialog.launchModal();
    });

    it('has the correct title', function() {
        expect(this.dialog.title).toMatchTranslation("hdfs_data_source.workspace_picker.title");
    });

    it('has the correct button title', function() {
        expect(this.dialog.submitButtonTranslationKey).toBe("hdfs_data_source.workspace_picker.button");
    });

    it('shows only non-archived workspaces', function() {
        expect(this.server.lastFetchAllFor(this.dialog.collection).url).
            toContainQueryParams({active: "true"});
    });

    describe("choosing a workspace and submitting the form",function(){
        beforeEach(function() {
            this.firstWorkspace = rspecFixtures.workspace();
            var workspaces = [
            this.firstWorkspace,
            rspecFixtures.workspace()
        ];
        this.server.completeFetchAllFor(this.dialog.collection, workspaces);
            this.dialog.$("li:eq(0)").click();
            this.dialog.$("button.submit").click();
        });

        it('launches the new work flow dialog', function() {
            expect(this.modalSpy).toHaveModal(chorus.dialogs.WorkFlowNewForHdfsEntryList);
            var lastModal = this.modalSpy.lastModal();
            expect(lastModal.options.workspace.id).toEqual(this.firstWorkspace.id);
            expect(lastModal.collection).toEqual(this.hdfsEntries);
        });
    });
});