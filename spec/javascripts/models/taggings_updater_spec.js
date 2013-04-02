describe("chorus.models.TaggingsUpdater", function() {
    beforeEach(function(){
        this.entity1 = rspecFixtures.dataset({id: 123});
        this.entity2 = rspecFixtures.dataset({id: 456});
        this.collection = new chorus.collections.Base([this.entity1.attributes, this.entity2.attributes]);
        this.tag = new chorus.models.Tag({name: "foo"});

        this.taggingsUpdater = new chorus.models.TaggingsUpdater({collection: this.collection, add: this.tag});

        spyOnEvent(this.taggingsUpdater, "saved");
        spyOnEvent(this.taggingsUpdater, "saveFailed");
    });

    it("posts to taggings", function() {
        this.taggingsUpdater.save();
        expect(this.server.lastCreate().url).toHaveUrlPath("/taggings");
    });

    it("posts the tags for all objects", function() {
        this.taggingsUpdater.save();

        var params = this.server.lastCreate().params();
        expect(params["taggables[0][entity_id]"]).toEqual('123');
        expect(params["taggables[1][entity_id]"]).toEqual('456');
        expect(params["add"]).toEqual('foo');
        expect(params["remove"]).toEqual();
    });

    it("triggers saved on the tagging set array", function() {
        this.taggingsUpdater.save();
        this.server.lastCreate().succeed();
        expect("saved").toHaveBeenTriggeredOn(this.taggingsUpdater);
    });

    it("triggers saveFailed the tagging set array", function() {
        this.taggingsUpdater.save();
        this.server.lastCreate().failForbidden();
        expect("saveFailed").toHaveBeenTriggeredOn(this.taggingsUpdater);
    });
});
