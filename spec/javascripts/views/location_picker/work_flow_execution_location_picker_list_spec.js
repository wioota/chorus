describe("chorus.views.WorkFlowExecutionLocationPickerList", function () {
    beforeEach(function () {
        this.view = new chorus.views.WorkFlowExecutionLocationPickerList();
    });

    describe("#ready", function () {
        it("is true if all subviews are ready", function () {
            _.each(this.view.pickers, function (picker) { spyOn(picker, 'ready').andReturn(true); });
            this.view.pickers[0].ready.andReturn(false);
            expect(this.view.ready()).toBeFalsy();

            this.view.pickers[0].ready.andReturn(true);
            expect(this.view.ready()).toBeTruthy();
        });
    });

    describe("change", function () {
        it("triggers when any of the pickers trigger change", function () {
            spyOn(this.view, 'trigger');

            this.view.pickers[0].trigger('change');

            expect(this.view.trigger).toHaveBeenCalledWith('change');
        });
    });

    describe("#render", function () {
        beforeEach(function () {
            this.view.render();
        });

        it("renders all the pickers", function () {
            expect(this.view.$el).toContainTranslation("sandbox.select.data_source");
        });
    });
});