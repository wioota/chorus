jasmine.sharedExamples.aDialogLauncher = function(linkHtmlClass, dialogClass) {
    context("clicking the " + linkHtmlClass + " link", function() {
        beforeEach(function() {
            this.modalSpy.reset();
            $('#jasmine_content').append(this.view.$el);
            chorus.page = this.page || this.view;
            this.view.$("a." + linkHtmlClass).click();
        });

        it("should launch the " + dialogClass.prototype.constructorName + " dialog once", function() {
            expect(this.modalSpy).toHaveModal(dialogClass);
            expect(this.modalSpy.modals().length).toBe(1);
        });
    });
};