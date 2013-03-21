describe("chorus.collections.SchemaSet", function() {
    beforeEach(function() {
        this.collection = rspecFixtures.schemaSet({ database: {id: '41' }} );
    });

    it("has the right URL", function() {
        this.collection.attributes.databaseId = "42";
        expect(this.collection.url()).toContain("/databases/42/schemas");
    });

    it("includes the DataSourceCredentials mixin", function() {
        expect(this.collection.dataSourceRequiringCredentials).toBe(chorus.Mixins.DataSourceCredentials.model.dataSourceRequiringCredentials);
    });

    describe("#sort", function() {
        beforeEach(function() {
            this.collection.reset([
                rspecFixtures.schema({ name: 'z'}),
                rspecFixtures.schema({ name: 'G'}),
                rspecFixtures.schema({ name: 'a'})
            ]);
        });

        it("sorts by name, case insensitive", function() {
            var names = this.collection.pluck('name');
            expect(names).toEqual(['a', 'G', 'z']);
        });
    });
});
