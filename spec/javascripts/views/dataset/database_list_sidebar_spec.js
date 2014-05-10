describe("chorus.views.DatabaseListSidebar", function() {
    beforeEach(function() {
        this.view = new chorus.views.DatabaseListSidebar();

        this.database = backboneFixtures.database();
        chorus.PageEvents.trigger("database:selected", this.database);
    });

    it("should display the database name", function() {
        expect(this.view.$(".name")).toContainText(this.database.get("name"));
    });

    it("displays the new name when a new database is selected", function() {
        var db = backboneFixtures.database();
        chorus.PageEvents.trigger("database:selected", db);
        expect(this.view.$(".name")).toContainText(db.get("name"));
    });

    it("displays the correct database type", function() {
        expect(this.view.$(".details")).toContainTranslation("database_list.sidebar.gpdb_database");
        this.pgDatabase = backboneFixtures.pgDatabase();
        chorus.PageEvents.trigger("database:selected", this.pgDatabase);
        expect(this.view.$(".details")).toContainTranslation("database_list.sidebar.pg_database");
    });

    it("displays nothing when a database is deselected", function() {
        chorus.PageEvents.trigger("database:deselected");
        expect(this.view.$(".info")).not.toExist();
    });
});
