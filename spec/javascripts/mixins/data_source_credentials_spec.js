describe("chorus.Mixins.DataSourceCredentials", function() {
    describe("model", function() {
        beforeEach(function() {
            this.collection = new chorus.collections.Base();
            spyOn(this.collection, "url").andReturn("some/url");
            _.extend(this.collection, chorus.Mixins.DataSourceCredentials.model);
        });

        describe("#dataSourceRequiringCredentials", function() {
            context('when a fetch failed because of missing data source credentials', function() {
                it("returns a data source model with the right id", function() {
                    var json = rspecFixtures.forbiddenDataSourceJson({ errors: { model_data: { id: 101 } } });

                    this.collection.fetch();
                    this.server.lastFetchFor(this.collection).respondJson(403, json);

                    var dataSource = this.collection.dataSourceRequiringCredentials();
                    expect(dataSource).toBeA(chorus.models.DataSource);
                    expect(dataSource.get("id")).toBe(101);
                });
            });
        });
    });

    describe("page", function() {
        beforeEach(function() {
            this.page = new chorus.pages.Base();
            this.model = new chorus.models.Base();
            this.otherModel = new chorus.models.Base();

            _.extend(this.page, chorus.Mixins.DataSourceCredentials.page);
            _.extend(this.model, chorus.Mixins.DataSourceCredentials.model);

            this.model.urlTemplate = "foo";
            this.otherModel.urlTemplate = "bar";

            this.page.handleFetchErrorsFor(this.model);
            this.page.handleFetchErrorsFor(this.otherModel);

            this.modalSpy = stubModals();
            spyOn(Backbone.history, 'loadUrl');

            this.model.fetch();
            this.otherModel.fetch();
        });

        describe("when a fetch fails for one of the page's required resources", function() {
            context("when credentials are missing", function() {
                beforeEach(function() {
                    this.dataSource = rspecFixtures.gpdbDataSource();
                    spyOn(this.model, 'dataSourceRequiringCredentials').andReturn(this.dataSource);
                    this.server.lastFetchFor(this.model).failForbidden();
                });

                it("does not go to the 403 page", function() {
                    expect(Backbone.history.loadUrl).not.toHaveBeenCalled();
                });

                it("launches the 'add credentials' dialog, and reloads after the credentials have been added", function() {
                    var dialog = this.modalSpy.lastModal();
                    expect(dialog).toBeA(chorus.dialogs.DataSourceAccount);
                    expect(dialog.options.dataSource).toBe(this.dataSource);
                    expect(dialog.options.title).toMatchTranslation("data_sources.account.add.title");
                });

                it("configure the dialog to reload after credentials are added and navigate back on dismissal", function() {
                    var dialog = this.modalSpy.lastModal();
                    expect(dialog.options.reload).toBeTruthy();
                    expect(dialog.options.goBack).toBeTruthy();
                });
            });

            function itGoesToThe404Page() {
                it("does go to the 404 page", function() {
                    expect(Backbone.history.loadUrl).toHaveBeenCalledWith("/invalidRoute");
                });

                it("does not launch any dialog", function() {
                    expect(this.modalSpy.lastModal()).not.toBeDefined();
                });
            }

            context("fetch failed for some other reason", function() {
                beforeEach(function() {
                    spyOn(this.model, 'dataSourceRequiringCredentials').andReturn(undefined);
                    this.server.lastFetchFor(this.model).failNotFound();
                });

                itGoesToThe404Page();
            });

            context("when the resource does not respond to #dataSourceRequiringCredentials", function() {
                beforeEach(function() {
                    this.server.lastFetchFor(this.otherModel).failNotFound([{
                        message: "Not found"
                    }]);
                });

                itGoesToThe404Page();
            });
        });
    });
});
