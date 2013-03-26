describe('chorus.pages.OracleSchemaIndexPage', function(){
    beforeEach(function() {
        this.oracle = rspecFixtures.oracleDataSource({name: "Davis"});
        this.page = new chorus.pages.OracleSchemaIndexPage(this.oracle.id);
        this.schemas = rspecFixtures.oracleSchemaSet([rspecFixtures.oracleSchema({name: "schema1"}), rspecFixtures.oracleSchema({name: "schema2"})]);
    });

    it("includes the DataSourceCredentials mixin", function() {
        expect(this.page.dependentResourceForbidden).toBe(chorus.Mixins.DataSourceCredentials.page.dependentResourceForbidden);
    });

    it('sets up the right collection', function(){
        expect(this.page.collection.url()).toBe(this.oracle.schemas().url());
    });

    it('fetches the collection', function(){
        expect(this.page.collection).toHaveBeenFetched();
    });

    context('when the data source and schemas have been fetched', function(){
        beforeEach(function() {
            this.server.completeFetchFor(this.page.dataSource, this.oracle);
            this.server.completeFetchFor(this.page.collection, this.schemas.models);
        });

        it("should have title in the mainContentList", function() {
            expect(this.page.mainContent.contentHeader.$("h1")).toContainText("Davis");
        });

        it("lists the schemas", function() {
            expect(this.page.mainContent.content.$el).toContainText("schema1");
            expect(this.page.mainContent.content.$el).toContainText("schema2");
        });

        it("set up search correctly", function() {
            expect(this.page.$(".list_content_details .count")).toContainTranslation("entity.name.Schema", {count: 2});
            expect(this.page.$("input.search")).toHaveAttr("placeholder", t("schema.search_placeholder"));
            expect(this.page.$(".list_content_details .explore")).toContainTranslation("actions.explore");

            this.page.$("input.search").val("schema1").trigger("keyup");

            expect(this.page.$(".item_wrapper:eq(1)")).toHaveClass("hidden");
            expect(this.page.$(".list_content_details .count")).toContainTranslation("entity.name.Schema", {count: 1});
            expect(this.page.mainContent.options.search.eventName).toBe("schema:search");
        });

        it("should have the correct breadcrumbs", function() {
            expect(this.page.$(".breadcrumb").length).toBe(3);

            expect(this.page.$(".breadcrumb:eq(0) a").attr("href")).toBe("#/");
            expect(this.page.$(".breadcrumb:eq(0)")).toContainTranslation("breadcrumbs.home");

            expect(this.page.$(".breadcrumb:eq(1) a").attr("href")).toBe("#/data_sources");
            expect(this.page.$(".breadcrumb:eq(1)")).toContainTranslation("breadcrumbs.instances");

            expect(this.page.$(".breadcrumb:eq(2)")).toContainText("Davis");
        });

        describe("the sidebar", function() {
            it("exists", function() {
                expect(this.page.sidebar).toBeA(chorus.views.SchemaListSidebar);
                expect(this.page.$(this.page.sidebar.el)).toExist();
            });

            it("includes the selected schemas name and type", function() {
                expect(this.page.sidebar.$el).toContainText("schema1");
                this.page.$('.item_wrapper:eq(1)').click();
                expect(this.page.sidebar.$el).toContainText("schema2");
                expect(this.page.sidebar.$el).toContainText("Oracle DB Schema");
            });
        });
    });

    context('when fetching the collection returns a 403', function(){
        var launchModalSpy;

        beforeEach(function() {
            launchModalSpy = spyOn(chorus.dialogs.InstanceAccount.prototype, 'launchModal');
            this.server.completeFetchFor(this.page.dataSource);
            this.server.lastFetchFor(this.page.collection).failForbidden({message: "Forbidden", model_data: {id: 'foo'}});
        });

        it("launches the InstanceAccount dialog", function() {
            expect(launchModalSpy).toHaveBeenCalled();
        });
    });
});