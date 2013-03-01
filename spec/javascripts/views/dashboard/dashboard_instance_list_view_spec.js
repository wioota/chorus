describe("chorus.views.DashboardInstanceList", function() {
    beforeEach(function(){
        this.instance1 = rspecFixtures.oracleDataSource({ name: "broccoli" });
        this.instance2 = rspecFixtures.hadoopInstance({ name: "Camels" });
        this.instance3 = rspecFixtures.hadoopInstance({ name: "doppler" });
        this.instance4 = rspecFixtures.gpdbDataSource({ name: "Ego" });
        this.instance5 = rspecFixtures.gpdbDataSource({ name: "fatoush" });
        this.instance6 = rspecFixtures.gnipInstance({ name: "kangaroo" });
        this.instance7 = rspecFixtures.gnipInstance({ name: "chicken" });
        this.collection = new chorus.collections.DataSourceSet([
            this.instance5,
            this.instance2,
            this.instance4,
            this.instance6,
            this.instance3,
            this.instance1,
            this.instance7
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
            expect(this.view.$(".name").eq(0)).toHaveHref(this.instance1.showUrl());

            expect(this.view.$(".name").eq(1)).toContainText("Camels");
            expect(this.view.$(".name").eq(1)).toHaveHref(this.instance2.showUrl());
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
            expect(this.view.$(".image img").eq(0).attr("src")).toBe(this.instance1.providerIconUrl());
            expect(this.view.$(".image img").eq(1).attr("src")).toBe(this.instance2.providerIconUrl());
        });
    });
});

