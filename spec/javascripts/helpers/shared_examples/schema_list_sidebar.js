jasmine.sharedExamples.aListSchemaSidebar = function() {
    describe("schema sidebar behavior", function () {
        beforeEach(function() {
            chorus.PageEvents.trigger("schema:selected", this.schema);
        });

        it("should display the schema name", function() {
            expect(this.view.$(".name")).toContainText(this.schema.get("name"));
        });

        it("displays the new name when a new schema is selected", function() {
            var schema = backboneFixtures.schema({name: "other"});
            chorus.PageEvents.trigger("schema:selected", schema);
            expect(this.view.$(".name")).toContainText("other");
        });

        it("displays nothing when a schema is deselected", function() {
            chorus.PageEvents.trigger("schema:deselected");
            expect(this.view.$(".info")).not.toExist();
        });

        it("displays the correct schema type", function() {
            expect(this.view.$(".details")).toContainTranslation("schema_list.sidebar.type." + this.schema.get("entityType"));
        });
    });

};
