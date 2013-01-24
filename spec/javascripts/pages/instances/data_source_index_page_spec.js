describe("chorus.pages.DataSourceIndexPage", function() {
    beforeEach(function() {
        this.page = new chorus.pages.DataSourceIndexPage();
        this.dataSourceSet = new chorus.collections.DataSourceSet();
        this.hadoopInstanceSet = new chorus.collections.HadoopInstanceSet();
        this.gnipInstanceSet = new chorus.collections.GnipInstanceSet();
    });

    it("has a helpId", function() {
        expect(this.page.helpId).toBe("instances");
    });

    it("fetches all data sources", function() {
        expect(this.dataSourceSet).toHaveBeenFetched();
    });

    it("fetches all hadoop instances", function() {
        expect(this.hadoopInstanceSet).toHaveBeenFetched();
    });

    it("fetches all gnip instances", function() {
        expect(this.gnipInstanceSet).toHaveBeenFetched();
    });

    it("passes the data sources and hadoop instances to the content details view", function() {
        var contentDetails = this.page.mainContent.contentDetails;
        expect(contentDetails.options.hadoopInstances).toBeA(chorus.collections.HadoopInstanceSet);
        expect(contentDetails.options.dataSources).toBeA(chorus.collections.DataSourceSet);
        expect(contentDetails.options.gnipInstances).toBeA(chorus.collections.GnipInstanceSet);
    });

    it("passes the data sources, hadoop and gnip instances to the list view", function() {
        var list = this.page.mainContent.content;
        expect(list.options.hadoopInstances).toBeA(chorus.collections.HadoopInstanceSet);
        expect(list.options.dataSources).toBeA(chorus.collections.DataSourceSet);
        expect(list.options.gnipInstances).toBeA(chorus.collections.GnipInstanceSet);
    });

    describe('#render', function(){
        beforeEach(function(){
            chorus.bindModalLaunchingClicks(this.page);
            this.page.render();
        });

        it("launches a new instance dialog", function() {
            var modal = stubModals();
            this.page.mainContent.contentDetails.$("button").click();
            expect(modal.lastModal()).toBeA(chorus.dialogs.InstancesNew);
        });

        it("sets the page model when a 'instance:selected' event is broadcast", function() {
            var instance = rspecFixtures.gpdbDataSource();
            expect(this.page.model).not.toBe(instance);
            chorus.PageEvents.broadcast('instance:selected', instance);
            expect(this.page.model).toBe(instance);
        });

        it("displays the loading text", function() {
            expect(this.page.mainContent.contentDetails.$(".loading")).toExist();
        });
    });

    describe("when the instances are fetched", function() {
        beforeEach(function() {
            this.server.completeFetchAllFor(this.dataSourceSet, [
                rspecFixtures.oracleDataSource(),
                rspecFixtures.gpdbDataSource()
            ]);

            this.server.completeFetchAllFor(this.hadoopInstanceSet, [
                rspecFixtures.hadoopInstance(),
                rspecFixtures.hadoopInstance()
            ]);
            this.server.completeFetchAllFor(this.gnipInstanceSet, [
                rspecFixtures.gnipInstance(),
                rspecFixtures.gnipInstance()
            ]);
        });

        describe("pre-selection", function() {
            it("pre-selects the first item by default", function() {
                expect(this.page.mainContent.content.$(".gpdb_data_source li.instance:eq(0)")).toHaveClass("selected");
            });
        });

        it("doesn't display the loading text", function() {
            expect(this.page.mainContent.contentDetails.$(".loading")).not.toExist();
        });

        it('displays the instance count', function(){
            expect(this.page.mainContent.contentDetails.$(".number").text()).toBe("6");
        });
    });
});
