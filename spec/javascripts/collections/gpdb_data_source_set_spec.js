describe("chorus.collections.GpdbDataSourceSet", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.GpdbDataSourceSet([
            backboneFixtures.gpdbDataSource({ name: "Gun_instance" }),
            backboneFixtures.gpdbDataSource({ name: "cat_instance" }),
            backboneFixtures.gpdbDataSource({ name: "Fat_instance" }),
            backboneFixtures.gpdbDataSource({ name: "egg_instance" }),
            backboneFixtures.gpdbDataSource({ name: "Dog_instance" })
        ]);
    });

    it("specifies an entity type when fetching", function() {
        expect(this.collection.urlParams().entityType).toBe("gpdb_data_source");
    });

    it('sorts the data sources by name, case insensitively', function() {
        expect(this.collection.at(0).get("name")).toBe("cat_instance");
        expect(this.collection.at(1).get("name")).toBe("Dog_instance");
        expect(this.collection.at(2).get("name")).toBe("egg_instance");
        expect(this.collection.at(3).get("name")).toBe("Fat_instance");
        expect(this.collection.at(4).get("name")).toBe("Gun_instance");
    });
});
