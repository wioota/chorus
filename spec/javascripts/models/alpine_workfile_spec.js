describe("chorus.models.AlpineWorkfile", function () {
    var workfile;
    beforeEach(function() {
        loadConfig();
        workfile = rspecFixtures.workfile.alpine();
    });

    it("has an 'alpine' as its entity subtype", function() {
        var workfile = new chorus.models.AlpineWorkfile();
        expect(workfile.get("entitySubtype")).toBe("alpine");
    });

    describe("iconUrl", function () {
        it("returns the afm icon", function () {
            expect(workfile.iconUrl()).toMatch(/afm\.png/);
        });

        it("returns the correct size", function () {
            expect(workfile.iconUrl({size: 'icon'})).toMatch(/icon.*afm\.png/);
        });
    });

    xdescribe("imageUrl", function() {
        it("matches the expected url", function() {
            expect(chorus.models.Config.instance().get('alpineUrl')).toBeDefined();
            expect(chorus.models.Config.instance().get('alpineApiKey')).toBeDefined();
            var uri = new URI({
                hostname: chorus.models.Config.instance().get('alpineUrl'),
                path: "/alpinedatalabs/main/chorus.do",
                query: "method=getWorkFlowImage&api_key=" + chorus.models.Config.instance().get('alpineApiKey') + "&id=" + workfile.get("alpineId")
            });
            expect(new URI(workfile.imageUrl()).equals(uri)).toBeTruthy();
        });
    });

    xdescribe("runUrl", function() {
        it("matches the expected url", function() {
            expect(chorus.models.Config.instance().get('alpineUrl')).toBeDefined();
            expect(chorus.models.Config.instance().get('alpineApiKey')).toBeDefined();
            var uri = new URI({
                hostname: chorus.models.Config.instance().get('alpineUrl'),
                path: "/alpinedatalabs/main/chorus.do",
                query: "method=runWorkFlow&api_key=" + chorus.models.Config.instance().get('alpineApiKey') + "&id=" + workfile.get("alpineId") + "&chorus_workfile_type=Workfile&chorus_workfile_id=" + workfile.get('id') + "&chorus_workfile_name=" + workfile.get('fileName')
            });
            expect(new URI(workfile.runUrl()).equals(uri)).toBeTruthy();
        });
    });
});