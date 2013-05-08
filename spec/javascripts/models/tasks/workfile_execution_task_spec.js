describe("chorus.models.WorkfileExecutionTask", function() {
    beforeEach(function() {
        this.workfile = rspecFixtures.workfile.sql({id: 1});
        this.model = new chorus.models.WorkfileExecutionTask({
            workfile: this.workfile,
            sql: "show tables"
        });
    });

    it("has the right URL", function() {
        expect(this.model.url()).toMatchUrl("/workfiles/1/executions");
    });

    it("name returns the name of the workfile", function() {
        expect(this.model.name()).toEqual(this.workfile.get("fileName"));
    });

    it("posts the correct data on save", function() {
        this.model.save();
        var params = this.server.lastCreate().params();
        expect(params['check_id']).toEqual(this.model.get("checkId"));
        expect(params['sql']).toEqual('show tables');
        expect(_.keys(params).length).toEqual(2);
    });

    it("mixes in SQLResults", function() {
        expect(this.model.columnOrientedData).toBeDefined();
    });

    it("sends the correct parameters on destroy", function() {
        this.model.cancel();
        var params = this.server.lastDestroy().params();
        expect(_.keys(params).length).toEqual(0);
    });

    describe("SQLResults support functions", function() {
        beforeEach(function() {
            this.columns = [ { name:"id" }, { name:"title"} ];
            this.rows = [ ['1', 'president'], ['2', 'vice president']];
            this.model = rspecFixtures.workfileExecutionResults({
                columns : this.columns,
                rows : this.rows
            });
            this.model.set({columns: this.columns});
        });

        describe("#getRows", function(){
            it("puts rows into the format data grids expect", function() {
                expect(this.model.getRows()).toEqual([
                    {id_0: "1", title_1: "president"},
                    {id_0: "2", title_1: "vice president"}
                ]);
            });
        });
    });
});
