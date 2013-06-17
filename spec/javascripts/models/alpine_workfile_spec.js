describe("chorus.models.AlpineWorkfile", function() {
    beforeEach(function() {
        loadConfig();
        this.model = rspecFixtures.workfile.alpine({
            fileName: "hello.afm",
            id: "23",
            workspace: {id: "32"},
            datasetIds: ["3", "4", "5"]
        });

        chorus.models.Config.instance().set({
            workFlowConfigured: true,
            workFlowUrl: "test.com"
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

    it("has the right iframeUrl", function() {
        var url = this.model.iframeUrl();

        expect(url).toHaveUrlPath("test.com/alpinedatalabs/main/chorus.do");
        expect(url).toContainQueryParams({
            database_id: this.model.get('executionLocation').id,
            file_name: "hello.afm",
            workfile_id: "23",
            session_id: "hex",
            method: "chorusEntry",
            "dataset_id[]": ["3", "4", "5" ]
        });
    });

    it("has the right imageUrl", function() {
        var url = this.model.imageUrl();

        expect(url).toHaveUrlPath("test.com/alpinedatalabs/main/chorus.do");
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
});