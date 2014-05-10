describe("chorus.views.SchemaListSidebar", function() {
    beforeEach(function() {
        this.view = new chorus.views.SchemaListSidebar();
    });

    describe("a gpdb schema", function () {
        beforeEach(function () {
            this.schema = backboneFixtures.schema();
        });
        itBehavesLike.aListSchemaSidebar();
    });

    describe("an oracle schema", function () {
        beforeEach(function () {
            this.schema = backboneFixtures.oracleSchema();
        });
        itBehavesLike.aListSchemaSidebar();
    });

    describe("a pg schema", function () {
        beforeEach(function () {
            this.schema = backboneFixtures.pgSchema();
        });
        itBehavesLike.aListSchemaSidebar();
    });

    describe("a jdbc schema", function () {
        beforeEach(function () {
            this.schema = backboneFixtures.oracleSchema({entityType:"jdbc_schema"});
        });
        itBehavesLike.aListSchemaSidebar();
    });
});

