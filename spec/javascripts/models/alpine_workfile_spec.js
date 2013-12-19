describe("chorus.models.AlpineWorkfile", function() {
    beforeEach(function() {
        loadConfig();
        this.model = backboneFixtures.workfile.alpine({
            fileName: "hello.afm",
            id: "23",
            workspace: {id: "32"},
            datasetIds: ["3", "4", "5"]
        });

        chorus.models.Config.instance().set({
            workflowConfigured: true
        });
        chorus.session.set("sessionId", "hex");
    });

    describe("showUrl", function() {
        it("has the normal workfile showUrl by default", function() {
            expect(this.model.showUrl()).toBe("#/workspaces/32/workfiles/23");
        });

        it("has a workflow showUrl", function() {
            expect(this.model.showUrl({workFlow: true})).toBe("#/work_flows/23");
        });
    });

    it("has an 'alpine' as its entity subtype", function() {
        this.model = new chorus.models.AlpineWorkfile();
        expect(this.model.get("entitySubtype")).toBe("alpine");
    });

    describe("iconUrl", function() {
        it("returns the afm icon", function() {
            expect(this.model.iconUrl()).toMatch(/afm\.png/);
        });

        it("returns the correct size", function() {
            expect(this.model.iconUrl({size: 'icon'})).toMatch(/icon.*afm\.png/);
        });
    });

    context('when the execution location is a gpdb database', function() {
        beforeEach(function () {
            this.model.set('executionLocations', [{ id: 'this_is_a_gpdb_database_id', entityType: 'gpdb_database' }]);
        });

        it("has the right iframeUrl", function() {
            var url = this.model.iframeUrl();

            expect(url).toHaveUrlPath("/alpinedatalabs/main/chorus.do");
            expect(url).toContainQueryParams({
                workfile_id: "23",
                session_id: "hex",
                method: "chorusEntry"
            });
            expect(url).not.toContainQueryParams({"hdfs_data_source_id[]": 'this_is_a_hadoop_id'});
        });
    });

    context('when the execution location is an hdfs data source', function() {

        context("when the workflow is based off of hdfs datasets", function() {
            beforeEach(function() {
                this.model = backboneFixtures.workfile.alpineHdfsDatasetFlow({
                    fileName: "hello.afm",
                    id: "23",
                    workspace: {id: "32"},
                    hdfsDatasetIds: [4,5,6],
                    executionLocations: [
                        { id: 'this_is_a_hadoop_id', entityType: 'hdfs_data_source' }
                    ]
                });
            });

            it("has the right iframeUrl", function() {
                var url = this.model.iframeUrl();

                expect(url).toHaveUrlPath("/alpinedatalabs/main/chorus.do");
                expect(url).toContainQueryParams({
                    workfile_id: "23",
                    session_id: "hex",
                    method: "chorusEntry"
                });
                expect(url).not.toContainQueryParams({"database_id[]": 'this_is_a_gpdb_database_id'});
            });
        });
    });

    context("when there are multiple datasources", function () {
        beforeEach(function () {
            this.model = backboneFixtures.workfile.alpineMultiDataSourceFlow({
                executionLocations: [
                    { id: 'this_is_a_hadoop_id', entityType: 'hdfs_data_source' },
                    { id: 'this_is_an_oracle_id', entityType: 'oracle_data_source' },
                    { id: 'this_is_a_gpdb_database_id', entityType: 'gpdb_database' }
                ]
            });
        });

        it("has the right iframeUrl", function() {
            var url = this.model.iframeUrl();

            expect(url).toHaveUrlPath("/alpinedatalabs/main/chorus.do");
            expect(url).toContainQueryParams({
                workfile_id: this.model.id,
                session_id: "hex",
                method: "chorusEntry"
            });
        });

        context("with datasets", function () {
            beforeEach(function () {
                this.model = backboneFixtures.workfile.alpineMultiDataSourceFlow({
                    datasetIds: ['1'],
                    hdfsDatasetIds: ['10', '11'],
                    oracleDatasetIds: ['1521'],
                    executionLocations: [
                        { id: 'this_is_a_hadoop_id', entityType: 'hdfs_data_source' },
                        { id: 'this_is_a_gpdb_database_id', entityType: 'gpdb_database' },
                        { id: 'this_is_an_oracle_data_source_id', entityType: 'oracle_data_source' }
                    ]
                });
            });

            it("has the right iframe url", function () {
                var url = this.model.iframeUrl();

                expect(url).toHaveUrlPath("/alpinedatalabs/main/chorus.do");
                expect(url).toContainQueryParams({
                    workfile_id: this.model.id,
                    session_id: "hex",
                    method: "chorusEntry"
                });
            });
        });
    });

    it("has the right imageUrl", function() {
        var url = this.model.imageUrl();

        expect(url).toHaveUrlPath("/alpinedatalabs/main/chorus.do");
        expect(url).toContainQueryParams({
            workfile_id: "23",
            session_id: "hex",
            method: "chorusImage"
        });
    });

    describe("canOpen", function () {
        beforeEach(function () {
            spyOn(this.model.workspace(), 'currentUserCanCreateWorkFlows');
        });

        it("delegates access conditions to the workspace", function () {
            this.model.canOpen();
            expect(this.model.workspace().currentUserCanCreateWorkFlows).toHaveBeenCalled();
        });
    });

    describe("workFlowShowUrl", function(){
        it("corresponds to the workflow show page's url", function(){
            expect(this.model.workFlowShowUrl()).toBe("#/work_flows/"+this.model.id);
        });
    });

    describe("dataSourceRequireingCredentials", function () {
        describe("when the error entity type is workspace", function () {
            it("is undefined", function () {
                this.model.serverErrors = {modelData: {entityType: 'workspace'}};
                expect(this.model.dataSourceRequiringCredentials()).toBeFalsy();
            });
        });

        describe("when the error entity type is not workspace", function () {
            it("delegates to the data source credentials mixin", function () {
                this.model.serverErrors = {modelData: {entityType: 'data_source'}};
                expect(this.model.dataSourceRequiringCredentials()).toBeA(chorus.models.GpdbDataSource);
            });
        });
    });

    describe("executionLocations", function() {
        it("creates models for each execution location", function() {
            spyOn(chorus.models, 'DynamicExecutionLocation').andCallThrough();
            expect(this.model.executionLocations()[0]).toBeA(chorus.models.Database);
            expect(chorus.models.DynamicExecutionLocation).toHaveBeenCalledWith(this.model.get('executionLocations')[0]);
        });
    });

});