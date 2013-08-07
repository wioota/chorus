describe("chorus.views.JobTaskItem", function () {
    beforeEach(function() {
        this.model = backboneFixtures.job().tasks().at(0);
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
});