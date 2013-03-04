describe("chorus.collections.DataSourceSet", function() {
    beforeEach(function() {
        this.collection = new chorus.collections.DataSourceSet();
    });
    it("has the correct url", function() {
        expect(this.collection.url()).toHaveUrlPath('/data_sources');
    });

    describe("#comparator", function() {
        it("sorts based on the lower cased name", function() {
            var model = new chorus.models.DataSource({name: 'Data Source'});
            expect(this.collection.comparator(model)).toBe('data source');
        });
    });

    describe("#urlParams", function() {
       it("contains the accessible attribute", function() {
           expect(this.collection.urlParams().accessible).toBeUndefined();
           this.collection.attributes.accessible = true;
           expect(this.collection.urlParams().accessible).toBe(true);
       });
    });
});