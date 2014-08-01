describe("chorus.views.MultipleSelectionSidebar", function() {
    var dialogConstructor = chorus.dialogs.ChangePassword;
    var method = 'enable';
    var actionName = 'add_data';
    var methodActionName = 'enable';

    beforeEach(function() {
        this.modalSpy = stubModals();
        this.selectEvent = "arbitrarily:anything";
        this.view = new chorus.views.MultipleSelectionSidebarMenu({
            actions: [
                {name: actionName, target: dialogConstructor},
                {name: methodActionName, target: method}
            ],
            selectEvent: this.selectEvent
        });
        this.view.render();
        $('#jasmine_content').append(this.view.el);
    });

    context("when no models are selected", function() {
        it("is not visible", function() {
            expect(this.view.$el).not.toBeVisible();
        });
    });

    context("when a model is selected", function() {
        beforeEach(function() {
            this.collection = new chorus.collections.Base([new chorus.models.Base()]);
            spyOn(this.collection, 'invoke');
            chorus.PageEvents.trigger(this.selectEvent, this.collection);
            this.view.render();
        });

        it("is visible", function() {
            expect(this.view.$el).toBeVisible();
        });

        it("shows the number of models selected", function() {
            expect(this.view.$('.title')).toContainTranslation('sidebar.selected', {count: 1});
        });

        it("lists the model names under the selected text", function() {
            var collection = new chorus.collections.Base([
                backboneFixtures.workfile.sql(),
                backboneFixtures.jdbcDataset(),
                backboneFixtures.oracleSchema()
            ]);
            chorus.PageEvents.trigger(this.selectEvent, collection);
            expect(this.view.$('.selected_models')).toContainText(Handlebars.helpers.modelNamesList(collection));
        });

        it("renders custom actions", function() {
            expect(this.view.$("li")).toContainTranslation('actions.'+actionName);
        });

        describe("zzz clicking a method action", function () {
            it("invokes the method on the selectedModels", function () {
                expect(this.collection.invoke).not.toHaveBeenCalled();
                this.view.$("."+methodActionName).click();
                expect(this.collection.invoke).toHaveBeenCalledWith(method);
            });
        });

        itBehavesLike.aDialogLauncher("."+actionName, dialogConstructor);

        describe("clicking deselect all link", function() {
            beforeEach(function() {
                spyOn(chorus.PageEvents, "trigger");
                this.view.$(".deselect_all").click();
            });

            it("triggers a selectNone event", function() {
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith("selectNone");
            });
        });
    });
});
