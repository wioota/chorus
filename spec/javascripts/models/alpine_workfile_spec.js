describe("chorus.models.AlpineWorkfile", function() {
    beforeEach(function() {
        loadConfig();
        this.model = rspecFixtures.workfile.alpine({
            databaseId: "3",
            fileName: "hello.afm",
            id: "23",
            workspace: {id: "32"}
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
            database_id: "3",
            file_name: "hello.afm",
            workfile_id: "23",
            session_id: "hex",
            method: "chorusEntry"
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
        context("when the workspace is active and the current user is a member", function () {
            it("returns true", function(){
               this.model.workspace().members().add(new chorus.models.User(chorus.session.user().attributes));
               expect(this.model.canOpen()).toBeTruthy();
            });
        });

        context("when the workspace is archived", function () {
            it("returns false", function () {
                this.model.workspace().set("archivedAt", true);
                expect(this.model.canOpen()).toBeFalsy();
            });
        });

        context("when the current user is not a member", function () {

            it("returns false", function () {
                this.model.workspace().members().reset();
                expect(this.model.canOpen()).toBeFalsy();
            });
        });
    });

    describe("workFlowShowUrl", function(){
       it("corresponds to the workflow show page's url", function(){
          expect(this.model.workFlowShowUrl()).toBe("#/work_flows/"+this.model.id);
       });
    });
});