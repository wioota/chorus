describe("chorus.views.HdfsDatasetContentDetails", function() {
    beforeEach(function() {
        this.model = backboneFixtures.workspaceDataset.hdfsDataset({fileMask: '/my_data/*'});
        this.view = new chorus.views.HdfsDatasetContentDetails({ model: this.model });
        this.view.render();
    });

    it("has the file mask", function() {
        expect(this.view.$el).toContainTranslation('hdfs_dataset.content_details.file_mask', {fileMask: '/my_data/*'});
    });

    it("has the readonly text", function() {
        expect(this.view.$el).toContainTranslation('hdfs.read_only');
    });
});