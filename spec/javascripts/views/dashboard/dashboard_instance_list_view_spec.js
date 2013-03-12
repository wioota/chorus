describe("chorus.views.DashboardInstanceList", function() {
    beforeEach(function(){
        this.dataSource1 = rspecFixtures.oracleDataSource({ name: "broccoli" });
        this.dataSource2 = rspecFixtures.hdfsDataSource({ name: "Camels" });
        this.dataSource3 = rspecFixtures.hdfsDataSource({ name: "doppler" });
        this.dataSource4 = rspecFixtures.gpdbDataSource({ name: "Ego" });
        this.dataSource5 = rspecFixtures.gpdbDataSource({ name: "fatoush" });
        this.dataSource6 = rspecFixtures.gnipDataSource({ name: "kangaroo" });
        this.dataSource7 = rspecFixtures.gnipDataSource({ name: "chicken" });
        this.collection = new chorus.collections.DataSourceSet([
            this.dataSource5,
            this.dataSource2,
            this.dataSource4,
            this.dataSource6,
            this.dataSource3,
            this.dataSource1,
            this.dataSource7
        ]);

        var proxySet = new chorus.collections.Base(
            _.map(this.collection.models, function(model) {
                return new chorus.models.Base({ theInstance: model });
            })
        );

        this.collection.loaded = true;
        proxySet.loaded = true;
        this.view = new chorus.views.DashboardInstanceList({ collection : proxySet });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.view.render();
        });

        it('displays the names of the data sources', function() {
            expect(this.view.$(".name").eq(0)).toContainText("broccoli");
            expect(this.view.$(".name").eq(0)).toHaveHref(this.dataSource1.showUrl());

            expect(this.view.$(".name").eq(1)).toContainText("Camels");
            expect(this.view.$(".name").eq(1)).toHaveHref(this.dataSource2.showUrl());
        });

        it('sorts the data sources case-insensitively', function() {
            expect(this.view.$(".name").eq(0)).toContainText("broccoli");
            expect(this.view.$(".name").eq(1)).toContainText("Camels");
            expect(this.view.$(".name").eq(2)).toContainText("chicken");
            expect(this.view.$(".name").eq(3)).toContainText("doppler");
            expect(this.view.$(".name").eq(4)).toContainText("Ego");
            expect(this.view.$(".name").eq(5)).toContainText("fatoush");
            expect(this.view.$(".name").eq(6)).toContainText("kangaroo");
        });

        it('displays the icon for each data source', function() {
            expect(this.view.$(".image img").eq(0).attr("src")).toBe(this.dataSource1.providerIconUrl());
            expect(this.view.$(".image img").eq(1).attr("src")).toBe(this.dataSource2.providerIconUrl());
        });
    });
});

