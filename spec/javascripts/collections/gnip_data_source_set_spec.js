describe("chorus.collections.GnipDataSourceSet", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.GnipDataSourceSet([
            rspecFixtures.gnipDataSource({ name: "Gun_instance" }),
            rspecFixtures.gnipDataSource({ name: "cat_instance" }),
            rspecFixtures.gnipDataSource({ name: "Fat_instance" }),
            rspecFixtures.gnipDataSource({ name: "egg_instance" }),
            rspecFixtures.gnipDataSource({ name: "Dog_instance" })
        ]);
    });

    it("has the right url", function() {
        expect(this.collection.url()).toHaveUrlPath("/gnip_data_sources");
    });

    it('sorts the data sources by name, case insensitively', function() {
        expect(this.collection.at(0).get("name")).toBe("cat_instance");
        expect(this.collection.at(1).get("name")).toBe("Dog_instance");
        expect(this.collection.at(2).get("name")).toBe("egg_instance");
        expect(this.collection.at(3).get("name")).toBe("Fat_instance");
        expect(this.collection.at(4).get("name")).toBe("Gun_instance");
    });

    describe("#urlParams", function() {
        it("contains the 'succinct' attribute", function() {
            expect(this.collection.urlParams().succinct).toBeUndefined();
            this.collection.attributes.succinct = true;
            expect(this.collection.urlParams().succinct).toBe(true);
        });
    });
});
