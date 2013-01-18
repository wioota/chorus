describe("chorus.models.AlpineWorkfile", function () {
    var workfile;
    beforeEach(function() {
        workfile = rspecFixtures.workfile.alpine();
    });

    describe("iconUrl", function () {
        it("returns the afm icon", function () {
            expect(workfile.iconUrl()).toMatch(/afm\.png/);
        });

        it("returns the correct size", function () {
            expect(workfile.iconUrl({size: 'icon'})).toMatch(/icon.*afm\.png/);
        });
    });

    describe("imageUrl", function() {
        beforeEach(function() {
            chorus.models.Config.instance();
            this.server.completeFetchFor(chorus.models.Config.instance(), rspecFixtures.config());
        });

        it("matches the expected url", function() {
            expect(chorus.models.Config.instance().get('alpineUrl')).toBeDefined();
            expect(chorus.models.Config.instance().get('alpinePort')).toBeDefined();
            expect(chorus.models.Config.instance().get('alpineApiKey')).toBeDefined();
            var uri = new URI({
                protocol: "http",
                hostname: chorus.models.Config.instance().get('alpineUrl'),
                port: chorus.models.Config.instance().get('alpinePort'),
                path: "/alpinedatalabs/main/chorus.do",
                query: "method=getWorkFlowImage&api_key=" + chorus.models.Config.instance().get('alpineApiKey') + "&id=" + workfile.get("alpineId")
            });
            expect(new URI(workfile.imageUrl()).equals(uri)).toBeTruthy();
        });
    });

    describe("runUrl", function() {
        beforeEach(function() {
            chorus.models.Config.instance();
            this.server.completeFetchFor(chorus.models.Config.instance(), rspecFixtures.config());
        });

        it("matches the expected url", function() {
            expect(chorus.models.Config.instance().get('alpineUrl')).toBeDefined();
            expect(chorus.models.Config.instance().get('alpinePort')).toBeDefined();
            expect(chorus.models.Config.instance().get('alpineApiKey')).toBeDefined();
            var uri = new URI({
                protocol: "http",
                hostname: chorus.models.Config.instance().get('alpineUrl'),
                port: chorus.models.Config.instance().get('alpinePort'),
                path: "/alpinedatalabs/main/chorus.do",
                query: "method=runWorkFlow&api_key=" + chorus.models.Config.instance().get('alpineApiKey') + "&id=" + workfile.get("alpineId") + "&chorus_workfile_type=Workfile&chorus_workfile_id=" + workfile.get('id')
            });
            expect(new URI(workfile.runUrl()).equals(uri)).toBeTruthy();
        });
    });
});