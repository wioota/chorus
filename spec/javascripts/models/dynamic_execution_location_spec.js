describe("chorus.models.DynamicExecutionLocation", function() {
    it("returns a database when the json is for a database", function() {
        var attrs = backboneFixtures.database().attributes;
        var model = new chorus.models.DynamicExecutionLocation(attrs);
        expect(model).toBeA(chorus.models.Database);
    });

    it("returns an hdfs data source when the json is for an hdfs data source", function() {
        var model = new chorus.models.DynamicExecutionLocation(backboneFixtures.hdfsDataSource().attributes);
        expect(model).toBeA(chorus.models.HdfsDataSource);
    });
});