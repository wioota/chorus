describe("chorus.views.JobTaskItem", function () {
    beforeEach(function() {
        this.collection = backboneFixtures.job().tasks();
        this.model = this.collection.at(0);
        this.view = new chorus.views.JobTaskItem({ model: this.model });
        this.view.render();
    });

    it("links the task's name to its show page", function() {
        expect(this.view.$(".name")).toHaveText(this.model.get("name"));
    });

    it("includes the correct task icon", function() {
        this.model.set('action', 'run_work_flow');
        expect(this.view.$("img")).toHaveAttr("src", "/images/jobs/afm-task.png");

        this.model.set('action', 'run_sql_file');
        expect(this.view.$("img")).toHaveAttr("src", "/images/workfiles/icon/sql.png");

        this.model.set('action', 'import_source_data');
        expect(this.view.$("img")).toHaveAttr("src", "/images/import_icon.png");
    });

    it("links the task's name to its show page", function() {
        expect(this.view.$(".action")).toContainTranslation("job_task.action." + this.model.get("action"));
    });

    describe("when the model received an 'invalidated' trigger", function() {
        beforeEach(function() {
            spyOn(this.model, "fetch");
        });

        it("reloads the model", function() {
            this.model.trigger("invalidated");
            expect(this.model.fetch).toHaveBeenCalled();
        });
    });

    describe("ordering arrows", function() {
        it("has a down arrow as the first item in the list", function() {
            this.model = this.collection.at(0);
            this.view.model = this.model;
            this.view.render();
            expect(this.view.$('.down_arrow')).toExist();
            expect(this.view.$('.up_arrow')).not.toExist();
        });

        it("has an up arrow as the last item in the list", function() {
            this.model = this.collection.at(this.collection.length - 1);
            this.view.model = this.model;
            this.view.render();
            expect(this.view.$('.down_arrow')).not.toExist();
            expect(this.view.$('.up_arrow')).toExist();
        });

        context("when the item is in the middle of the collection", function() {
            beforeEach(function() {
                this.model = this.collection.at(1);
                this.view = new chorus.views.JobTaskItem({ model: this.model });
                this.view.render();
            });

            it("has both an up and down arrow as an", function() {
                expect(this.view.$('.down_arrow')).toExist();
                expect(this.view.$('.up_arrow')).toExist();
            });

            function itReordersTheList() {
                it("makes a request to re-order the list ", function() {
                    expect(this.server.lastUpdateFor(this.model)).toBeTruthy();
                });

                context("when the request finishes", function() {
                    beforeEach(function() {
                        chorus.page = {};
                        chorus.page.model = this.model.job();
                        spyOn(chorus.page.model, 'trigger');
                        this.server.completeUpdateFor(this.model);
                    });

                    it("invalidates the job model", function() {
                        expect(chorus.page.model.trigger).toHaveBeenCalledWith('invalidated');
                    });
                });
            }

            context("when the down arrow is clicked", function() {
                beforeEach(function() {
                    this.view.$('.down_arrow').click();
                });

                itReordersTheList();
            });

            context("when the up arrow is clicked", function() {
                beforeEach(function() {
                    this.view.$('.up_arrow').click();
                });

                itReordersTheList();
            });
        });
    });
});