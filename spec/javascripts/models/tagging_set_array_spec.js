describe("chorus.models.taggingSetArray", function() {
    beforeEach(function(){
        this.taggingSet1 = new chorus.collections.TaggingSet([
            {name: "foo"},
            {name: "bar"}
        ], { entity: rspecFixtures.dataset({id: 123}) });

        this.taggingSet2 = new chorus.collections.TaggingSet([
            {name: "foo2"},
            {name: "bar2"}
        ], { entity: rspecFixtures.dataset({id: 456}) });

        this.taggingSetArray = new chorus.models.TaggingSetArray({taggingSets: [this.taggingSet1, this.taggingSet2]});

        spyOnEvent(this.taggingSetArray, "saved");
        spyOnEvent(this.taggingSetArray, "saveFailed");
    });

    it("posts to taggings", function() {
        this.taggingSetArray.save();
        expect(this.server.lastCreate().url).toHaveUrlPath("/taggings");
    });

    it("posts the tags for all objects", function() {
        this.taggingSetArray.save();

        var params = this.server.lastCreate().params();
        expect(params["taggings[0][entity_id]"]).toEqual('123');
        expect(params["taggings[0][tag_names][]"]).toEqual(['foo', 'bar']);

        expect(params["taggings[1][entity_id]"]).toEqual('456');
        expect(params["taggings[1][tag_names][]"]).toEqual(['foo2', 'bar2']);
    });

    it("triggers saved on the tagging set array", function() {
        this.taggingSetArray.save();
        this.server.lastCreate().succeed();
        expect("saved").toHaveBeenTriggeredOn(this.taggingSetArray);
    });

    it("triggers saveFailed the tagging set array", function() {
        this.taggingSetArray.save();
        this.server.lastCreate().failForbidden();
        expect("saveFailed").toHaveBeenTriggeredOn(this.taggingSetArray);
    });
});
