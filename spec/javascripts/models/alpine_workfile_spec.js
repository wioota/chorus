describe("chorus.models.AlpineWorkfile", function() {
    beforeEach(function() {
        loadConfig();
        this.model = rspecFixtures.workfile.alpine({
            databaseId: "3",
            fileName: "hello.afm",
            id: "23",
            workspace: {id: "32"}
        });
    });

    describe("showUrl", function() {
        it("has the normal workfile showUrl by default", function() {
            expect(this.model.showUrl()).toBe("#/workspaces/32/workfiles/23");
        });

        it("has a workflow showUrl", function() {
            expect(this.model.showUrl({workFlow: true})).toBe("#/workFlows/23");
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

    describe("iframeUrl", function() {
        beforeEach(function() {
            chorus.models.Config.instance().set({
                workFlowConfigured: true,
                workFlowUrl: "test.com"
            });
            chorus.session.set("sessionId", "hex");
        });

        it("has the right url", function() {
            var url = this.model.iframeUrl();

            expect(url.hostname()).toEqual("test.com");
            expect(url).toHaveUrlPath("/alpinedatalabs/main/chorus.do");
            expect(url).toContainQueryParams({
                database_id: "3",
                file_name: "hello.afm",
                workfile_id: "23",
                session_id: "hex"
            });
        });
    });

    xdescribe("imageUrl", function() {
        it("matches the expected url", function() {
            expect(chorus.models.Config.instance().get('alpineUrl')).toBeDefined();
            expect(chorus.models.Config.instance().get('alpineApiKey')).toBeDefined();
            var uri = new URI({
                hostname: chorus.models.Config.instance().get('alpineUrl'),
                path: "/alpinedatalabs/main/chorus.do",
                query: "method=getWorkFlowImage&api_key=" + chorus.models.Config.instance().get('alpineApiKey') + "&id=" + this.model.get("alpineId")
            });
            expect(new URI(this.model.imageUrl()).equals(uri)).toBeTruthy();
        });
    });

    xdescribe("runUrl", function() {
        it("matches the expected url", function() {
            expect(chorus.models.Config.instance().get('alpineUrl')).toBeDefined();
            expect(chorus.models.Config.instance().get('alpineApiKey')).toBeDefined();
            var uri = new URI({
                hostname: chorus.models.Config.instance().get('alpineUrl'),
                path: "/alpinedatalabs/main/chorus.do",
                query: "method=runWorkFlow&api_key=" + chorus.models.Config.instance().get('alpineApiKey') + "&id=" + this.model.get("alpineId") + "&chorus_workfile_type=Workfile&chorus_workfile_id=" + this.model.get('id') + "&chorus_workfile_name=" + this.model.get('fileName')
            });
            expect(new URI(this.model.runUrl()).equals(uri)).toBeTruthy();
        });
    });
});