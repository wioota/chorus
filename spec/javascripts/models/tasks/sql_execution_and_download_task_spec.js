describe("chorus.models.SqlExecutionAndDownloadTask", function() {
    beforeEach(function() {
        this.model = new chorus.models.SqlExecutionAndDownloadTask({
            workfileId: '1',
            sql: 'select 2',
            schemaId: '5',
            numOfRows: '6'
        });
    });

    describe("save", function() {
        it("starts a file download", function() {
            spyOn($, 'fileDownload');
            this.model.save();
            expect($.fileDownload).toHaveBeenCalled();
            expect($.fileDownload.mostRecentCall.args[0]).toBe('/workfiles/1/executions');
        });
    });
});