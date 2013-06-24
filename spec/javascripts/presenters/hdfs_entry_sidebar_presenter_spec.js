describe("chorus.presenters.HdfsEntrySidebar", function() {
    describe("entityId", function() {
        beforeEach(function() {
            this.model = backboneFixtures.hdfsFile();
            this.presenter = new chorus.presenters.HdfsEntrySidebar(this.model, {});
        });

        it("returns the id of the resource", function() {
            expect(this.presenter.entityId()).toBe(this.model.id);
        });

        context("when the resource is null", function() {
            it("does not raise an error", function() {
                this.presenter = new chorus.presenters.HdfsEntrySidebar(null, {});
                this.presenter.entityId();
            });
        });
    });

    describe("lastUpdatedStamp", function() {
        it("returns a formatted timestamp", function() {
            var lastUpdated = "2013-06-21T22:00:58Z";
            this.model = backboneFixtures.hdfsFile({lastUpdatedStamp: lastUpdated});
            this.presenter = new chorus.presenters.HdfsEntrySidebar(this.model, {});
            expect(this.presenter.lastUpdatedStamp()).toEqual(t("hdfs.last_updated", {when: Handlebars.helpers.relativeTimestamp(lastUpdated)}));
        });

        context("when the resource is null", function() {
            it("does not raise an error", function() {
                this.presenter = new chorus.presenters.HdfsEntrySidebar(null, {});
                this.presenter.lastUpdatedStamp();
            });
        });
    });
});