describe("chorus.models.TaggingsUpdater", function() {
    beforeEach(function(){
        this.entity1 = rspecFixtures.dataset({id: 123});
        this.entity2 = rspecFixtures.dataset({id: 456});
        this.collection = new chorus.collections.Base([this.entity1.attributes, this.entity2.attributes]);
        this.tag = new chorus.models.Tag({name: "foo"});

        this.taggingsUpdater = new chorus.models.TaggingsUpdater({collection: this.collection});

        spyOnEvent(this.taggingsUpdater, "updated");
        spyOnEvent(this.taggingsUpdater, "updateFailed");
    });

    describe("adding a tag", function() {
        beforeEach(function() {
            this.taggingsUpdater.updateTags({add: this.tag});
        });

        it("posts to taggings", function() {
            expect(this.server.lastCreate().url).toHaveUrlPath("/taggings");
        });

        it("posts the added tag to the taggings for all objects", function() {
            var params = this.server.lastCreate().params();
            expect(params["taggables[0][entity_id]"]).toEqual('123');
            expect(params["taggables[1][entity_id]"]).toEqual('456');
            expect(params["add"]).toEqual('foo');
            expect(params["remove"]).toEqual();
        });

        context("when the update succeeds", function() {
            beforeEach(function() {
                this.server.lastCreate().succeed();
            });

            it("triggers updated on the tagging set array", function() {
                expect("updated").toHaveBeenTriggeredOn(this.taggingsUpdater);
            });
        });

        context("when the update failed", function() {
            beforeEach(function() {
                spyOn(chorus, "toast");
                this.server.lastCreate().failForbidden();
            });

            it("triggers updateFailed on the taggings", function() {
                expect("updateFailed").toHaveBeenTriggeredOn(this.taggingsUpdater);
            });

            it("pops up a toast", function() {
                expect(chorus.toast).toHaveBeenCalled();
            });
        });

        context("with multiple tag updates", function() {
            it("does not call save for the second tag until the first tag completes saving", function() {
                var tag2 = new chorus.models.Tag({name: "bar"});
                expect(this.server.requests.length).toBe(1);
                this.taggingsUpdater.updateTags({add: tag2});
                expect(this.server.requests.length).toBe(1);
                this.server.lastCreate().succeed();
                expect(this.server.requests.length).toBe(2);
            });

            it("handles queueing correctly even when first tagging request fails", function() {
                var tag2 = new chorus.models.Tag({name: "bar"});
                expect(this.server.requests.length).toBe(1);
                this.taggingsUpdater.updateTags({add: tag2});
                expect(this.server.requests.length).toBe(1);
                this.server.lastCreate().failForbidden();
                expect(this.server.requests.length).toBe(2);
            });
        });
    });

    describe("removing a tag", function() {
        beforeEach(function() {
            this.taggingsUpdater.updateTags({remove: this.tag});
        });

        it("posts the remove tag options to taggings for all objects", function() {
            var params = this.server.lastCreate().params();
            expect(params["taggables[0][entity_id]"]).toEqual('123');
            expect(params["taggables[1][entity_id]"]).toEqual('456');
            expect(params["remove"]).toEqual('foo');
            expect(params["add"]).toEqual();
        });
    });
});
