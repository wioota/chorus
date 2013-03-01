describe("chorus.views.InstanceIndexContentDetails", function() {
    beforeEach(function() {
        var dataSources = new chorus.collections.DataSourceSet([
            rspecFixtures.gpdbDataSource(),
            rspecFixtures.gpdbDataSource()
        ]);
        var hadoopInstances = new chorus.collections.HadoopInstanceSet([
            rspecFixtures.hadoopInstance(),
            rspecFixtures.hadoopInstance()
        ]);
        var gnipInstances = new chorus.collections.GnipInstanceSet([
            rspecFixtures.gnipInstance(),
            rspecFixtures.gnipInstance()
        ]);

        this.view = new chorus.views.InstanceIndexContentDetails({
            dataSources: dataSources,
            hadoopInstances: hadoopInstances,
            gnipInstances: gnipInstances
        });
    });

    describe('#render', function() {
        beforeEach(function(){
            this.view.render();
        });

        it("displays the loading text", function() {
            expect(this.view.$(".loading")).toExist();
        });
    });

    describe("when the instances are loaded", function() {
        beforeEach(function() {
            this.view.dataSources.loaded = true;
            this.view.dataSources.trigger('loaded');
            this.view.hadoopInstances.loaded = true;
            this.view.hadoopInstances.trigger('loaded');
            this.view.gnipInstances.loaded = true;
            this.view.gnipInstances.trigger('loaded');
        });

        it("doesn't display the loading text", function() {
            expect(this.view.$(".loading")).not.toExist();
        });

        it('shows the data sources count', function() {
            expect(this.view.$(".number")).toContainText(6);
        });
    });
});