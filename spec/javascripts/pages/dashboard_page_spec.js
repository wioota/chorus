describe("chorus.pages.DashboardPage", function() {
    beforeEach(function() {
        chorus.session = new chorus.models.Session({ id: "foo" });
        this.page = new chorus.pages.DashboardPage();
    });

    it("has a helpId", function() {
        expect(this.page.helpId).toBe("dashboard");
    });

    it("fetches all the collections", function() {
        expect(this.page.userSet).toHaveBeenFetched();
        expect(this.page.dataSourceSet).toHaveBeenFetched();
        expect(this.page.hdfsDataSourceSet).toHaveBeenFetched();
        expect(this.page.gnipDataSourceSet).toHaveBeenFetched();
        expect(this.page.workspaceSet).toHaveBeenFetched();
    });

    describe("#render", function() {
        beforeEach(function() {
            this.server.completeFetchAllFor(this.page.dataSourceSet, [
                                         rspecFixtures.gpdbDataSource(),
                                         rspecFixtures.oracleDataSource()
            ]);
            this.server.completeFetchAllFor(this.page.hdfsDataSourceSet, [
                                         rspecFixtures.hdfsDataSource(),
                                         rspecFixtures.hdfsDataSource()
            ]);
            this.server.completeFetchAllFor(this.page.gnipDataSourceSet, [
                                         rspecFixtures.gnipDataSource(),
                                         rspecFixtures.gnipDataSource()
            ]);

            this.page.render();
        });

        it("creates a Header view", function() {
            expect(this.page.$("#header.header")).toExist();
        });

        context("the workspace list", function() {
            beforeEach(function() {
                this.workspaceList = this.page.mainContent.workspaceList;
            });

            it("has a title", function() {
                expect(this.workspaceList.$("h1").text()).toBe("My Workspaces");
            });

            it("creates a WorkspaceList view", function() {
                expect(this.page.$(".dashboard_workspace_list")).toExist();
            });
        });

        it("does not have a sidebar", function() {
            expect(this.page.$("#sidebar_wrapper")).not.toExist();
        });

        context("when the users fetch completes", function() {
            beforeEach(function() {
                this.server.completeFetchAllFor(
                    this.page.userSet,
                    rspecFixtures.userSet()
                );
            });

            it("shows the number of users", function() {
                expect(this.page.$("#user_count a")).toContainTranslation("dashboard.user_count", {count: rspecFixtures.userSet().length});
                expect(this.page.$("#user_count")).not.toHaveClass("hidden");
            });
        });
    });

    context("#setup", function() {
        beforeEach(function() {
            this.server.completeFetchAllFor(this.page.dataSourceSet, [
                rspecFixtures.gpdbDataSource(),
                rspecFixtures.oracleDataSource()
            ]);

            this.server.completeFetchAllFor(this.page.hdfsDataSourceSet, [
                rspecFixtures.hdfsDataSource(),
                rspecFixtures.hdfsDataSource()
            ]);

            this.server.completeFetchAllFor(this.page.gnipDataSourceSet, [
                rspecFixtures.gnipDataSource(),
                rspecFixtures.gnipDataSource()
            ]);
        });

        it("sets chorus.session.user as the model", function() {
            expect(this.page.model).toBe(chorus.session.user());
        });

        it("gets the number of users", function() {
            expect(this.server.lastFetchFor(new chorus.collections.UserSet([], {page:1, per_page:1}))).toBeTruthy();
        });

        it("passes the collection through to the workspaceSet view", function() {
            expect(this.page.mainContent.workspaceList.collection).toBe(this.page.workspaceSet);
        });

        it("fetches active workspaces for the current user, including recent comments", function() {
            expect(this.page.workspaceSet.attributes.showLatestComments).toBeTruthy();
        });

        it("should sort the workspaceSet by name ascending", function() {
            expect(this.page.workspaceSet.order).toBe("name");
        });

        it("passes the active to workspaceSet", function() {
            expect(this.page.workspaceSet.attributes.active).toBe(true);
        });

        it("passes succinct to workspaceSet", function() {
            expect(this.page.workspaceSet.attributes.succinct).toBe(true);
        });

        it("passes the userId to workspaceSet", function() {
            expect(this.page.workspaceSet.attributes.userId).toBe("foo");
        });

        it("fetches only the data sources where the user has permissions succinctly", function() {
            expect(this.page.dataSourceSet.attributes.succinct).toBe(true);
            expect(this.page.dataSourceSet).toBeA(chorus.collections.DataSourceSet);
            expect(this.page.dataSourceSet).toHaveBeenFetched();
        });

        it('fetches the hadoop data sources', function() {
            expect(this.page.hdfsDataSourceSet.attributes.succinct).toBe(true);
            expect(this.page.hdfsDataSourceSet).toBeA(chorus.collections.HdfsDataSourceSet);
            expect(this.page.hdfsDataSourceSet).toHaveBeenFetched();
        });

        it('fetches the gnip data sources', function() {
            expect(this.page.gnipDataSourceSet.attributes.succinct).toBe(true);
            expect(this.page.gnipDataSourceSet).toBeA(chorus.collections.GnipDataSourceSet);
            expect(this.page.gnipDataSourceSet).toHaveBeenFetched();
        });

        it('passes the data source set through to the data source list view', function() {
            var packedUpDataSourceSet = this.page.dataSourceSet.map(function(dataSource) {
                return new chorus.models.Base(dataSource);
            });
            var packedUpHadoopSet = this.page.hdfsDataSourceSet.map(function(dataSource) {
                return new chorus.models.Base(dataSource);
            });
            var packedUpGnipSet = this.page.gnipDataSourceSet.map(function(dataSource) {
                return new chorus.models.Base(dataSource);
            });
            var entireDataSourceSet = new chorus.collections.Base();
            entireDataSourceSet.add(packedUpDataSourceSet);
            entireDataSourceSet.add(packedUpGnipSet);
            entireDataSourceSet.add(packedUpHadoopSet);

            expect(entireDataSourceSet.length).toBe(this.page.mainContent.instanceList.collection.length);
        });

        describe('when a data source is added', function() {
            beforeEach(function() {
                spyOn(this.page, "fetchInstances");
                chorus.PageEvents.broadcast("instance:added");
            });

            it('re-fetches all data sources', function() {
                expect(this.page.fetchInstances).toHaveBeenCalled();
            });
        });
    });

    describe('#fetchInstances', function(){
        beforeEach(function() {
            spyOn(this.page.gnipDataSourceSet, "fetchAll");
            spyOn(this.page.hdfsDataSourceSet, "fetchAll");
            this.page.fetchInstances();
        });

        it("fetches all gnip and hadoop instances", function() {
            expect(this.page.gnipDataSourceSet.fetchAll).toHaveBeenCalled();
            expect(this.page.hdfsDataSourceSet.fetchAll).toHaveBeenCalled();
        });
    });
});
