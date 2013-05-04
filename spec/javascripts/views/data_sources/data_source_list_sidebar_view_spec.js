jasmine.sharedExamples.aSidebar = function() {
    it('displays data source name', function() {
        expect(this.view.$(".data_source_name")).toContainText(this.dataSource.get("name"));
    });

    it('displays data source type', function() {
        expect(this.view.$(".data_source_type")).toContainText(t("data_sources.provider." + this.dataSource.get('entityType')));
    });

    it("has a 'add a note' link", function() {
        expect(this.view.$("a[data-dialog=NotesNew]")).toExist();
        expect(this.view.$("a[data-dialog=NotesNew]").text()).toMatchTranslation("actions.add_note");
        expect(this.view.$("a[data-dialog=NotesNew]").data("workfileAttachments")).toBeFalsy();
        expect(this.view.$("a[data-dialog=NotesNew]").data("entityType")).toBe(this.dataSource.entityType);
    });

    describe('clicking the edit tags link', function() {
        beforeEach(function() {
            this.modalSpy = stubModals();
            this.view.$('.edit_tags').click();
        });

        it('opens the tag edit dialog', function() {
            expect(this.modalSpy).toHaveModal(chorus.dialogs.EditTags);
            expect(this.modalSpy.lastModal().collection.length).toBe(1);
            expect(this.modalSpy.lastModal().collection).toContain(this.dataSource);
        });
    });
};

jasmine.sharedExamples.aSidebarWithAGreenplumOrOracleDataSourceSelected = function() {
    context('when the data source has a shared account', function() {
        beforeEach(function() {
            this.dataSource.set({
                shared: true
            });
            this.dataSource._accountForCurrentUser = rspecFixtures.dataSourceAccount();
            this.view.render();
        });

        it("does not show the 'edit credentials' link", function() {
            expect(this.view.$(".actions .edit_credentials")).not.toExist();
        });

        it("does not show the 'add credentials' link", function() {
            expect(this.view.$(".actions .add_credentials")).not.toExist();
        });

        it('displays the data source shared account info', function() {
            expect(this.view.$(".data_source_configuration_details .shared_account_info")).toContainText(this.dataSource.accountForOwner().get("dbUsername"));
        });

        it('displays edit data source link when user is admin', function() {
            setLoggedInUser({ username: "benjamin", admin: true});
            this.view.render();
            expect(this.view.$(".actions .edit_data_source")).toExist();
        });

        it('displays edit data source link when user is owner', function() {
            setLoggedInUser({ username: "benjamin", admin: false});
            this.dataSource.accounts().reset([rspecFixtures.dataSourceAccount({owner: {id: chorus.session.user().get('id')}})]);
            this.dataSource.set({owner: {id: chorus.session.user().get('id')}});
            this.view.render();
            expect(this.view.$(".actions .edit_data_source")).toExist();
        });

        it('does NOT display the edit data source link when user is not an admin or owner', function() {
            setLoggedInUser({ username: "benjamin", admin: false});
            this.view.render();
            expect(this.view.$(".actions .edit_data_source")).not.toExist();
        });

        it("shows shared account information", function() {
            expect(this.view.$(".account_info")).toContainTranslation("data_sources.sidebar.is_shared_account");
        });
    });

    context('when the data source does not have a shared account', function() {
        context('when the current user is NOT an admin or owner of the data source', function() {
            context('when the user does not have an account for the data source', function() {
                it("shows the 'no access' text and image", function() {
                    expect(this.view.$(".account_info img").attr("src")).toBe("/images/data_sources/no_access.png");
                    expect(this.view.$(".account_info").text().trim()).toMatchTranslation("data_sources.sidebar.no_access");
                });

                it("shows the add credentials link", function() {
                    var addCredentialsLink = this.view.$(".actions a.add_credentials");
                    expect(addCredentialsLink).toExist();
                    expect(addCredentialsLink.data("dialog")).toBe("DataSourceAccount");
                    expect(addCredentialsLink.data("title")).toMatchTranslation("data_sources.account.add.title");
                    expect(addCredentialsLink.text()).toMatchTranslation("data_sources.sidebar.add_credentials");
                    expect(addCredentialsLink.data("dataSource")).toBe(this.dataSource);
                });

                it("does not show the 'edit credentials' link", function() {
                    expect(this.view.$(".actions .edit_credentials")).not.toExist();
                });

                it("does not show the 'remove credentials' link", function() {
                    expect(this.view.$(".actions .remove_credentials")).not.toExist();
                });
            });

            context('when the user has set up an account for the data source', function() {
                beforeEach(function() {
                    var account = rspecFixtures.dataSourceAccount();
                    spyOn(this.dataSource, 'accountForCurrentUser').andReturn(account);
                    this.view.render();
                });

                it("shows the 'access' text and image", function() {
                    expect(this.view.$(".account_info img").attr("src")).toBe("/images/data_sources/access.png");
                    expect(this.view.$(".account_info").text().trim()).toMatchTranslation("data_sources.sidebar.access");
                });

                it("shows the 'remove credentials' link", function() {
                    expect(this.view.$(".actions .remove_credentials").text()).toMatchTranslation("data_sources.sidebar.remove_credentials");
                });

                it("shows the 'edit credentials' link", function() {
                    var editCredentialsLink = this.view.$(".actions .edit_credentials");
                    expect(editCredentialsLink).toExist();
                    expect(editCredentialsLink.data("dialog")).toBe("DataSourceAccount");
                    expect(editCredentialsLink.data("title")).toMatchTranslation("data_sources.account.edit.title");
                    expect(editCredentialsLink.text()).toMatchTranslation("data_sources.sidebar.edit_credentials");
                    expect(editCredentialsLink.data("dataSource")).toBe(this.dataSource);
                });

                it("does not show the 'add credentials' link", function() {
                    expect(this.view.$(".actions .add_credentials")).not.toExist();
                });

                describe("when the user removes their credentials", function() {
                    beforeEach(function() {
                        this.dataSource.accountForCurrentUser = this.dataSource.accountForCurrentUser.originalValue;
                        this.dataSource.accountForCurrentUser().trigger("destroy");
                        this.view.render();
                    });

                    it("shows the add credentials link", function() {
                        expect(this.view.$(".actions .add_credentials")).toExist();
                        expect(this.view.$(".actions .add_credentials").data("dialog")).toBe("DataSourceAccount");
                        expect(this.view.$(".actions .add_credentials").data("title")).toMatchTranslation("data_sources.account.add.title");
                        expect(this.view.$(".actions .add_credentials").text()).toMatchTranslation("data_sources.sidebar.add_credentials");
                    });
                });
            });
        });

        context("when the current user is an admin", function() {
            beforeEach(function() {
                var account = rspecFixtures.dataSourceAccount();
                spyOn(this.dataSource, 'accountForCurrentUser').andReturn(account);
                this.dataSource.accounts().add([rspecFixtures.dataSourceAccount(), rspecFixtures.dataSourceAccount(), rspecFixtures.dataSourceAccount({id: null})]);
                setLoggedInUser({ username: "benjamin", admin: true});
                this.view.render();
            });

            it("does not show the individual_account area", function() {
                expect(this.view.$('.individual_account')).not.toBeVisible();
            });

            it("does not show the add/edit/remove credentials links", function() {
                expect(this.view.$(".actions .remove_credentials")).not.toBeVisible();
                expect(this.view.$(".actions .edit_credentials")).not.toBeVisible();
                expect(this.view.$(".actions .add_credentials")).not.toBeVisible();
            });

            it("shows the edit_individual_accounts area", function() {
                var editAccountsSection = this.view.$(".edit_individual_accounts"),
                    editAccountsLink = editAccountsSection.find("a");

                expect(editAccountsSection).toBeVisible();
                expect(editAccountsLink).toBeVisible();
                expect(this.view.$(".individual_accounts_count").text()).toMatchTranslation('data_sources.sidebar.there_are_x_individual_accounts', {count: 4});
                expect(editAccountsLink.data("dataSource")).toBe(this.dataSource);
                expect(editAccountsLink.data("dialog")).toBe("DataSourcePermissions");
            });
        });
    });

    it("calls super in postRender (so that scrolling works)", function() {
        expect(chorus.views.Sidebar.prototype.postRender).toHaveBeenCalled();
    });

    it("renders ActivityList subview", function() {
        expect(this.view.$(".activity_list")).toBeVisible();
    });

    it("populates the ActivityList with the activities", function() {
        expect(chorus.views.ActivityList.mostRecentCall.args[0].collection).toBe(this.dataSource.activities());
    });

    it("sets the ActivityList displayStyle to without_object", function() {
        expect(chorus.views.ActivityList.mostRecentCall.args[0].displayStyle).toBe('without_object');
    });

    context('when user is an admin or owner of the data source', function() {
        it('displays edit data source link when user is admin', function() {
            setLoggedInUser({ username: "benjamin", admin: true});
            this.view.render();
            expect(this.view.$(".actions .edit_data_source")).toExist();
        });

        it('displays edit data source link when user is owner', function() {
            setLoggedInUser({ username: "benjamin", admin: false});
            this.dataSource.set({owner: {id: chorus.session.user().get('id')} });
            this.view.render();
            expect(this.view.$(".actions .edit_data_source")).toExist();
        });

        it('does not display the delete data source link', function() {
            expect(this.view.$(".actions .delete_data_source")).not.toExist();
        });

        context('when the data source is offline', function() {
            beforeEach(function() {
                setLoggedInUser({ username: "benjamin", admin: true});
                this.dataSource.set({
                    online: false
                });
                this.view.render();
            });

            it('does display the edit data source link', function() {
                expect(this.view.$(".actions .edit_data_source")).toExist();
            });

            it("does display the edit accounts link", function() {
                expect(this.view.$("a[data-dialog=DataSourcePermissions]")).toExist();
            });
        });
    });

    context('when user is not an admin or owner of the data source', function() {
        beforeEach(function() {
            setLoggedInUser({ username: "benjamin", admin: false});
            this.dataSource.set({owner: {id: "harry"}});
            this.view.render();
        });

        it('does not display edit data source link when user is neither admin nor owner', function() {
            expect(this.view.$(".actions .edit_data_source")).not.toExist();
        });

        it('does not display the delete data source link', function() {
            expect(this.view.$(".actions .delete_data_source")).not.toExist();
        });
    });
};

describe("chorus.views.DataSourceListSidebar", function() {
    context('when no data source is selected', function() {
        beforeEach(function() {
            this.view = new chorus.views.DataSourceListSidebar();
            this.view.render();
        });

        describe("render", function() {
            it('should not display data source information', function() {
                expect(this.view.$(".info")).not.toExist();
            });
        });
    });

    context('when a gpdb data source is selected', function() {
        beforeEach(function() {
            this.dataSource = rspecFixtures.gpdbDataSource({name: "Harry's House of Glamour", version: "99.999" });
            this.activityViewStub = stubView("", { className: "activity_list" });
            spyOn(chorus.views, 'ActivityList').andReturn(this.activityViewStub);

            spyOn(chorus.views.Base.prototype, "render").andCallThrough();
            this.view = new chorus.views.DataSourceListSidebar();
            chorus.PageEvents.trigger("data_source:selected", this.dataSource);
            $('#jasmine_content').append(this.view.el);
        });

        it('fetches the activities, data source usage and accounts', function() {
            expect(this.dataSource.activities()).toHaveBeenFetched();
            expect(this.dataSource.usage()).toHaveBeenFetched();
            expect(this.dataSource.accounts()).toHaveAllBeenFetched();
        });

        context("when the data has been loaded", function() {
            beforeEach(function() {
                spyOn(chorus.views.Sidebar.prototype, 'postRender');
                this.server.completeFetchFor(this.dataSource.activities());
                var dataSourceAccountSet = rspecFixtures.dataSourceAccountSet();
                dataSourceAccountSet.models[0].set({owner: {id: this.dataSource.owner().id}});
                this.server.completeFetchAllFor(this.dataSource.accounts(), dataSourceAccountSet.models);
                this.server.completeFetchFor(this.dataSource.accountForCurrentUser());
            });

            itBehavesLike.aSidebar();
            itBehavesLike.aSidebarWithAGreenplumOrOracleDataSourceSelected();

            context("when configuration is clicked", function() {
                beforeEach(function() {
                    expect(this.view.$(".data_source_configuration_details")).not.toBeVisible();
                    this.view.$(".tab_control .tabs li[data-name=configuration]").click();
                });

                it("shows configuration", function() {
                    expect(this.view.$(".data_source_configuration_details")).not.toHaveClass("hidden");
                    expect(this.view.$(".activity_list")).toHaveClass("hidden");
                });

                it("shows the database version", function() {
                    expect(this.view.$(".data_source_configuration_details")).toContainTranslation("data_sources.version");
                    expect(this.view.$(".data_source_configuration_details")).toContainText("99.999");
                });

                it("shows the owner", function() {
                    expect(this.view.$(".data_source_configuration_details")).toContainTranslation("data_sources.permissions.owner");
                    expect(this.view.$(".data_source_configuration_details")).toContainText(this.dataSource.owner().displayName());
                });

                describe('for existing greenplum data source', function() {
                    context('and the data source has a shared account', function() {
                        beforeEach(function() {
                            var dataSource = rspecFixtures.gpdbDataSource({"shared": true});
                            dataSource.loaded = true;
                            this.view.setDataSource(dataSource);
                            this.server.completeFetchFor(dataSource.usage(), { workspaces: [] });
                            var dataSourceAccountSet = rspecFixtures.dataSourceAccountSet();
                            dataSourceAccountSet.models[0].set({owner: {id: this.dataSource.owner().id}});
                            this.server.completeFetchFor(dataSource.accounts(), dataSourceAccountSet.models);
                            this.server.completeFetchFor(dataSource.accountForCurrentUser());
                        });

                        it("includes the shared account information", function() {
                            expect(this.view.$(".data_source_configuration_details").text()).toContainTranslation("data_sources.shared_account");
                        });
                    });

                    context('and the data source does not have a shared account', function() {
                        it("does not include the shared account information", function() {
                            this.view.render();
                            expect(this.view.$(".data_source_configuration_details").text()).not.toContainTranslation("data_sources.shared_account");
                        });
                    });
                });

                describe('for a new gpdbdata source', function() {
                    beforeEach(function() {
                        this.view.model = this.view.model.set({ size: "1", port: null, host: null });
                        this.view.render();
                    });

                    it("includes gpdb size information", function() {
                        expect(this.view.$(".data_source_configuration_details").text().indexOf(t("data_sources.sidebar.size"))).not.toBe(-1);
                    });

                    it("does not include the port, host, or shared account information", function() {
                        expect(this.view.$(".data_source_configuration_details").text().indexOf(t("data_sources.sidebar.host"))).toBe(-1);
                        expect(this.view.$(".data_source_configuration_details").text().indexOf(t("data_sources.sidebar.port"))).toBe(-1);
                        expect(this.view.$(".data_source_configuration_details").text().indexOf(t("data_sources.shared_account"))).toBe(-1);
                    });
                });
            });

            it("has the default loading text on the workspace usage link", function() {
                expect(this.view.$(".actions .workspace_usage")).toContainTranslation("data_sources.sidebar.usage_loading");
            });

            context("when the workspace usage fetch completes", function() {
                beforeEach(function() {
                    this.server.completeFetchFor(this.dataSource.usage(), rspecFixtures.dataSourceDetails());
                });

                context("when there are no workspaces", function() {
                    beforeEach(function() {
                        this.dataSource.usage().set({workspaces: []});
                        this.dataSource.usage().trigger("loaded");
                    });

                    it("should disable the link", function() {
                        expect(this.view.$('.actions .workspace_usage')).toHaveClass('disabled');
                        expect(this.view.$('.actions .workspace_usage').data('dialog')).toBeUndefined();
                    });

                    it("should show a count of zero", function() {
                        expect(this.view.$('.actions .workspace_usage')).toContainTranslation('data_sources.sidebar.usage', {count: 0});
                    });
                });

                context("when there are workspaces", function() {
                    beforeEach(function() {
                        expect(this.dataSource.usage().get("workspaces").length).toBeGreaterThan(0);
                    });

                    it("should be a dialog link", function() {
                        expect(this.view.$('.actions .workspace_usage')).not.toHaveClass("disabled");
                        expect(this.view.$('.actions .workspace_usage')).toHaveClass("dialog");
                        expect(this.view.$(".actions .workspace_usage")).toHaveData("data_source", this.dataSource);
                    });

                    it("should show the appropriate number of workspaces", function() {
                        expect(this.view.$('.actions .workspace_usage')).toContainTranslation('data_sources.sidebar.usage', {count: this.dataSource.usage().get("workspaces").length});
                    });
                });
            });
        });

        context("when the user doesn't have permission to fetch the data source workspace usage", function() {
            beforeEach(function() {
                this.server.completeFetchFor(this.dataSource.activities());
                this.server.completeFetchAllFor(this.dataSource.accounts());
                this.server.completeFetchFor(this.dataSource.accountForCurrentUser());
                this.server.completeFetchFor(this.dataSource.usage(), rspecFixtures.dataSourceDetailsWithoutPermission());
            });

            it("renders without the workspace usage section", function() {
                expect(this.view.$(".data_source_name").text()).toBe("Harry's House of Glamour");
                expect(this.view.$('.actions .workspace_usage')).not.toExist();
            });
        });
    });

    context('when a oracle data source is selected', function() {
        beforeEach(function() {
            this.dataSource = rspecFixtures.oracleDataSource({name: "Harry's House of Glamour", version: "99.999" });
            this.activityViewStub = stubView("", { className: "activity_list" });
            spyOn(chorus.views, 'ActivityList').andReturn(this.activityViewStub);

            spyOn(chorus.views.Base.prototype, "render").andCallThrough();
            this.view = new chorus.views.DataSourceListSidebar();
            chorus.PageEvents.trigger("data_source:selected", this.dataSource);
            $('#jasmine_content').append(this.view.el);
        });

        it('fetches the activities, data source usage and accounts', function() {
            expect(this.dataSource.activities()).toHaveBeenFetched();
            expect(this.dataSource.usage()).toHaveBeenFetched();
            expect(this.dataSource.accounts()).toHaveAllBeenFetched();
        });

        context("when the data has been loaded", function() {
            beforeEach(function() {
                spyOn(chorus.views.Sidebar.prototype, 'postRender');
                this.server.completeFetchFor(this.dataSource.activities());
                var dataSourceAccountSet = rspecFixtures.dataSourceAccountSet();
                dataSourceAccountSet.models[0].set({owner: {id: this.dataSource.owner().id}});
                this.server.completeFetchAllFor(this.dataSource.accounts(), dataSourceAccountSet.models);
                this.server.completeFetchFor(this.dataSource.accountForCurrentUser());
            });

            itBehavesLike.aSidebar();
            itBehavesLike.aSidebarWithAGreenplumOrOracleDataSourceSelected();

            context("when configuration is clicked", function() {
                beforeEach(function() {
                    expect(this.view.$(".data_source_configuration_details")).not.toBeVisible();
                    this.view.$(".tab_control .tabs li[data-name=configuration]").click();
                });

                it("shows configuration", function() {
                    expect(this.view.$(".data_source_configuration_details")).not.toHaveClass("hidden");
                    expect(this.view.$(".activity_list")).toHaveClass("hidden");
                });

                describe('for existing data source', function() {
                    context('and the data source has a shared account', function() {
                        beforeEach(function() {
                            var dataSource = rspecFixtures.oracleDataSource({shared: true});
                            dataSource.loaded = true;
                            this.view.setDataSource(dataSource);
                            var dataSourceAccountSet = rspecFixtures.dataSourceAccountSet();
                            dataSourceAccountSet.models[0].set({owner: {id: this.dataSource.owner().id}});
                            this.server.completeFetchFor(dataSource.accounts(), dataSourceAccountSet.models);
                            this.server.completeFetchFor(dataSource.accountForCurrentUser());
                        });

                        it("includes the shared account information", function() {
                            expect(this.view.$(".data_source_configuration_details").text().indexOf(t("data_sources.shared_account"))).not.toBe(-1);
                        });
                    });

                    context('and the data source does not have a shared account', function() {
                        it("does not include the shared account information", function() {
                            this.view.render();
                            expect(this.view.$(".data_source_configuration_details").text().indexOf(t("data_sources.shared_account"))).toBe(-1);
                        });
                    });
                });

                describe('for a new data source', function() {
                    beforeEach(function() {
                        this.view.model = this.view.model.set({ size: "1", port: null, host: null });
                        this.view.render();
                    });

                    it("includes size information", function() {
                        expect(this.view.$(".data_source_configuration_details").text().indexOf(t("data_sources.sidebar.size"))).not.toBe(-1);
                    });

                    it("does not include the port, host, or shared account information", function() {
                        expect(this.view.$(".data_source_configuration_details").text().indexOf(t("data_sources.sidebar.host"))).toBe(-1);
                        expect(this.view.$(".data_source_configuration_details").text().indexOf(t("data_sources.sidebar.port"))).toBe(-1);
                        expect(this.view.$(".data_source_configuration_details").text().indexOf(t("data_sources.shared_account"))).toBe(-1);
                    });
                });
            });
        });
    });

    context('when a hadoop data source is selected', function() {
        beforeEach(function() {
            this.dataSource = rspecFixtures.hdfsDataSource({
                name: "Harry's House of Glamour",
                username: "hadoop",
                groupList: "hadoop",
                owner: {id: chorus.session.user().get('id')}
            });
            this.view = new chorus.views.DataSourceListSidebar();
            chorus.PageEvents.trigger("data_source:selected", this.dataSource);
            this.server.completeFetchFor(this.dataSource.activities());
        });

        it("does not display edit permissions link", function() {
            expect(this.view.$("a.dialog[data-dialog=DataSourcePermissions]")).not.toExist();
        });

        it('does display the edit data source link', function() {
            expect(this.view.$(".actions .edit_data_source")).toExist();
        });

        itBehavesLike.aSidebar();

        it("shows the shared account", function() {
            var shared_account_info = this.dataSource.get("username") + ", " + this.dataSource.get("groupList");
            expect(this.view.$(".data_source_configuration_details .shared_account_info")).toContainText(shared_account_info);
        });
    });

    context('when a gnip data source is selected', function() {
        beforeEach(function() {
            this.dataSource = rspecFixtures.gnipDataSource({name: "Harry's House of Glamour", username: "gnip" });
            this.view = new chorus.views.DataSourceListSidebar();
            chorus.PageEvents.trigger("data_source:selected", this.dataSource);
            this.server.completeFetchFor(this.dataSource.activities());
        });

        itBehavesLike.aSidebar();

        it("has a 'import stream' link", function() {
            expect(this.view.$("a[data-dialog=ImportGnipStream]")).toExist();
            expect(this.view.$("a[data-dialog=ImportGnipStream]").text()).toMatchTranslation("actions.import_gnip_stream");
        });

        it("shows the shared account", function() {
            var shared_account_info = this.dataSource.get("username");
            expect(this.view.$(".data_source_configuration_details .shared_account_info")).toContainText(shared_account_info);
        });

        it("shows the stream url", function() {
            var shared_account_info = this.dataSource.get("streamUrl");
            expect(this.view.$(".data_source_configuration_details .streamUrl")).toContainText(shared_account_info);
        });
    });

    describe("#launchRemoveCredentialsAlert", function() {
        beforeEach(function() {
            this.view = new chorus.views.DataSourceListSidebar();
            this.view.render();
            this.dataSource = rspecFixtures.gpdbDataSource({name: "Harry's House of Glamour", version: "99.999" });
            this.view.setDataSource(this.dataSource);
            this.modalSpy = stubModals();
        });

        it("launches the remove credentials modal", function(){
            this.view.launchRemoveCredentialsAlert();
            expect(this.modalSpy).toHaveModal(chorus.alerts.DataSourceAccountDelete);
            expect(this.modalSpy.lastModal().pageModel).toBe(this.dataSource);
        });
    });
});