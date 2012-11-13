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

    describe("saveFailed", function() {
        var saveFailed;
        beforeEach(function() {
            saveFailed = jasmine.createSpy('saveFailed');
            this.model.on('saveFailed', saveFailed);
            this.model.saveFailed('<pre>{"errors":"foo"}</pre>');
        });

        it("should save error data", function() {
            expect(this.model.serverErrors).toEqual('foo');
        });

        it("should trigger saveFailed", function() {
            expect(saveFailed).toHaveBeenCalledWith(this.model);
        });
    });
});