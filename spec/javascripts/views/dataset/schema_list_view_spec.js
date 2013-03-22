describe("chorus.views.SchemaList", function() {
    beforeEach(function() {
        this.schema1 = rspecFixtures.schema({name: 'schema_first'});
        this.schema2 = rspecFixtures.schema({name: 'schema_last', datasetCount: 1});
        this.schema3 = rspecFixtures.schema({name: 'schema_refreshing', refreshedAt: null});
        this.collection = rspecFixtures.schemaSet();
        this.collection.reset([this.schema1, this.schema2, this.schema3]);

        this.view = new chorus.views.SchemaList({collection: this.collection});
        this.view.render();
    });

    it("renders each item in the collection", function() {
        expect(this.view.$(".schema_item").length).toBe(3);
    });

    it("displays each schema's name with a link to the schema", function() {
        expect(this.view.$(".schema_item a.name").eq(0)).toContainText(this.schema1.get("name"));
        expect(this.view.$(".schema_item a.name").eq(0)).toHaveHref(this.schema1.showUrl());
    });

    it("displays the right icon for each schema", function() {
        expect(this.view.$(".schema_item img").eq(0)).toHaveAttr("src", "/images/data_sources/greenplum_schema.png");
    });

    it("displays the dataset count for each schema", function() {
        expect(this.view.$(".schema_item .description").eq(0)).toContainTranslation("entity.name.WorkspaceDataset", { count: this.schema1.get("datasetCount") });
    });

    describe("when the refreshed_at is null", function() {
        it("displays a message", function() {
            expect(this.view.$(".schema_item .description").eq(2)).toContainTranslation("entity.name.WorkspaceDataset.refreshing");
        });
    });

    it("broadcasts a schema:selected event when itemSelected is called", function() {
        spyOn(chorus.PageEvents, "broadcast");
        this.view.itemSelected(this.schema2);
        expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith("schema:selected", this.schema2);
    });
});
