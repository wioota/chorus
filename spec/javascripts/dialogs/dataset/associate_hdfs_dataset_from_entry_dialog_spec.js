describe("chorus.dialogs.AssociateHdfsDatasetFromEntry", function() {
    beforeEach(function() {
        this.entry = backboneFixtures.hdfsFile();
        this.dialog = new chorus.dialogs.AssociateHdfsDatasetFromEntry({entry: this.entry});

        this.modalSpy = stubModals();
        this.dialog.launchModal();
    });

    it("shows the right title", function() {
        expect(this.dialog.title).toMatchTranslation("associate_hdfs_dataset_from_entry.title");
    });

    it("should prefill name from selected file name", function() {
        expect(this.dialog.$('input.name').val()).toEqual(this.entry.get('name'));
    });

    it("should prefill file mask from the selected file's paths", function() {
        expect(this.dialog.$('input.file_mask').val()).toEqual(this.entry.get('path'));
    });
});