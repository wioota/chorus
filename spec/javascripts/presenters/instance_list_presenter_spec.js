describe("chorus.presenters.InstanceList", function() {
    var dataSources, hadoopInstances, gnipInstances, presenter;

    beforeEach(function() {
        dataSources = new chorus.collections.DataSourceSet([
            rspecFixtures.gpdbDataSource({ name: "joe_instance", online: true }),
            rspecFixtures.gpdbDataSource({ online: false })
        ]);

        hadoopInstances = new chorus.collections.HadoopInstanceSet([
            rspecFixtures.hadoopInstance({ online: false }),
            rspecFixtures.hadoopInstance({ description: "special instance", online: true }),
            rspecFixtures.hadoopInstance()
        ]);

        gnipInstances = new chorus.collections.GnipInstanceSet([
            rspecFixtures.gnipInstance({ name: "Gnip1" }),
            rspecFixtures.gnipInstance({ name: "Gnip2" }),
            rspecFixtures.gnipInstance({ name: "Gnip3", description: "I am a turnip" })
        ]);
        
        presenter = new chorus.presenters.InstanceList({
            dataSources: dataSources,
            hadoop: hadoopInstances,
            gnip: gnipInstances
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

        presenter = new chorus.presenters.InstanceList({
            dataSources: new chorus.collections.DataSourceSet(),
            hadoop: new chorus.collections.HadoopInstanceSet(),
            gnip: new chorus.collections.GnipInstanceSet()

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

            hadoopInstances.each(function(model, i) {
                expect(presenter.hadoop[i][name]).toBe(model.get(name));
            });

            gnipInstances.each(function(model, i) {
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

            hadoopInstances.each(function(model, i) {
                expect(presenter.hadoop[i][presentedName]).toBe(model[methodName]());
            });

            gnipInstances.each(function(model, i) {
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
});
