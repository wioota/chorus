describe("chorus.presenters.DataSourceList", function() {
    var dataSources, hdfsDataSources, gnipDataSources, presenter;

    beforeEach(function() {
        dataSources = new chorus.collections.DataSourceSet([
            rspecFixtures.gpdbDataSource({ name: "joe_instance", online: true }),
            rspecFixtures.gpdbDataSource({ online: false })
        ]);

        hdfsDataSources = new chorus.collections.HdfsDataSourceSet([
            rspecFixtures.hdfsDataSource({ online: false }),
            rspecFixtures.hdfsDataSource({ description: "special instance", online: true }),
            rspecFixtures.hdfsDataSource()
        ]);

      gnipDataSources = new chorus.collections.GnipDataSourceSet([
            rspecFixtures.gnipDataSource({ name: "Gnip1" }),
            rspecFixtures.gnipDataSource({ name: "Gnip2" }),
            rspecFixtures.gnipDataSource({ name: "Gnip3", description: "I am a turnip" })
        ]);
        
        presenter = new chorus.presenters.DataSourceList({
            dataSources: dataSources,
            hadoop: hdfsDataSources,
            gnip: gnipDataSources
        });
        presenter.present();
    });

    it("returns an object with three arrays 'greenplum', 'hadoop', and 'gnip'", function() {
        expect(presenter.dataSources.length).toBe(2);
        expect(presenter.hadoop.length).toBe(3);
        expect(presenter.gnip.length).toBe(3);
    });

    it("has the keys 'hasGreenplum', 'hasHadoop' and 'hasGnip'", function() {
        expect(presenter.hasDataSources).toBeTruthy();
        expect(presenter.hasHadoop).toBeTruthy();
        expect(presenter.hasGnip).toBeTruthy();

        presenter = new chorus.presenters.DataSourceList({
            dataSources: new chorus.collections.DataSourceSet(),
            hadoop: new chorus.collections.HdfsDataSourceSet(),
            gnip: new chorus.collections.GnipDataSourceSet()

        });

        expect(presenter.hasDataSources).toBeFalsy();
        expect(presenter.hasHadoop).toBeFalsy();
        expect(presenter.hasGnip).toBeFalsy();
    });

    describe("#present", function() {
        it("returns the presenter", function() {
            expect(presenter.present()).toBe(presenter);
        });
    });

    function itPresentsModelAttribute(name) {
        it("presents each model's " + name + " attribute", function() {
            dataSources.each(function(model, i) {
                expect(presenter.dataSources[i][name]).toBe(model.get(name));
            });

            hdfsDataSources.each(function(model, i) {
                expect(presenter.hadoop[i][name]).toBe(model.get(name));
            });

            gnipDataSources.each(function(model, i) {
                expect(presenter.gnip[i][name]).toBe(model.get(name));
            });
        });
    }

    function itPresentsModelMethod(methodName, presentedName) {
        presentedName || (presentedName = methodName);

        it("presents each model's " + methodName + " method as '" + presentedName + "''", function() {
            dataSources.each(function(model, i) {
                expect(presenter.dataSources[i][presentedName]).toBe(model[methodName]());
            });

            hdfsDataSources.each(function(model, i) {
                expect(presenter.hadoop[i][presentedName]).toBe(model[methodName]());
            });

            gnipDataSources.each(function(model, i) {
                expect(presenter.gnip[i][presentedName]).toBe(model[methodName]());
            });
        });
    }

    itPresentsModelMethod("stateIconUrl", "stateUrl");
    itPresentsModelMethod("showUrl");
    itPresentsModelMethod("providerIconUrl", "providerUrl");
    itPresentsModelMethod("stateText");

    itPresentsModelAttribute("id");
    itPresentsModelAttribute("name");
    itPresentsModelAttribute("description");

    it("presents the tags for all data sources", function() {
        var presenterPropertyMap = {
            dataSources: dataSources,
            hadoop: hdfsDataSources,
            gnip: gnipDataSources
        };

        _.each(presenterPropertyMap, function(presentedCollection, presenterProperty) {
           presentedCollection.each(function(model, i) {
               expect(presenter[presenterProperty][i]["tags"]).toBe(model.tags().models);
           });
        });
    });

});
