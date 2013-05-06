describe("chorus.alerts.DataSourceDelete", function() {
    beforeEach(function() {
        this.dataSource = rspecFixtures.gpdbDataSource();
        this.alert = new chorus.alerts.DataSourceDelete({ model: this.dataSource });
    });

    describe("successful deletion", function() {
        beforeEach(function() {
            spyOn(chorus, "toast");
            this.alert.model.trigger("destroy", this.alert.model);
        });

        it("displays a toast message", function() {
            expect(chorus.toast).toHaveBeenCalledWith("data_sources.delete.toast", {dataSourceName: this.dataSource.name()});
        });
    });

    describe("for a hdfs data source", function() {
        beforeEach(function() {
            this.alert.model = rspecFixtures.hdfsDataSource();
        });

        it("has the correct text", function() {
            expect(this.alert.additionalContext().text).toMatchTranslation('data_sources.delete.text.hdfs_data_source');
        });
    });

    describe("for a greenplum data source", function() {
        beforeEach(function() {
            this.alert.model = rspecFixtures.gpdbDataSource();
        });

        it("has the correct text", function() {
            expect(this.alert.additionalContext().text).toMatchTranslation('data_sources.delete.text.gpdb_data_source');
        });
    });

    describe("for an oracle data source", function() {
        beforeEach(function() {
            this.alert.model = rspecFixtures.oracleDataSource();
        });

        it("has the correct text", function() {
            expect(this.alert.additionalContext().text).toMatchTranslation('data_sources.delete.text.oracle_data_source');
        });
    });
});
