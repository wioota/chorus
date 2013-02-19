describe("chorus.dialogs.RenameTag", function() {
    beforeEach(function() {
        this.tag = new chorus.models.Tag({name: "testTag", id: 123});
        this.dialog = new chorus.dialogs.RenameTag({model: this.tag});
        this.dialog.render();
        this.input = this.dialog.$el.find('.rename_tag_input');
    });

    describe("#render", function() {
       it("has the tag's name in the text field", function() {
          expect(this.input).toHaveValue("testTag");
       });
    });

    describe("renaming a tag", function() {
        it("saves the tag", function() {
            this.input.val("new-tag-name");
            this.dialog.$('form').submit();
            this.server.completeUpdateFor(this.tag, this.tag.attributes);
        });

        it("enables the button for a new name", function() {
            this.input.val("different-name").keyup();
            expect(this.dialog.$("button[type=submit]")).not.toBeDisabled();
        });

        it("disables the button initially because the name hasn't changed", function() {
            expect(this.dialog.$("button[type=submit]")).toBeDisabled();
        });

        it("disables the button when the name is the same as the original name", function() {
            this.input.val(this.tag.name()).keyup();
            expect(this.dialog.$("button[type=submit]")).toBeDisabled();
        });

        it("disables the button when the name is cleared", function() {
            this.input.val("").keyup();
            expect(this.dialog.$("button[type=submit]")).toBeDisabled();
        });

        it("displays a validation error when tag name is too long", function() {
            this.input.val(_.repeat("a", 101)).keyup();
            expect(this.dialog.$("button[type=submit]")).toBeDisabled();
            expect(this.input).toHaveClass("has_error");
        });

        context("after an error is displayed", function() {
            it("clears the errors when a new value is entered", function() {
                this.input.val("").keyup();
                expect(this.input).toHaveClass("has_error");

                this.input.val("a-good-tag").keyup();
                expect(this.dialog.$("button[type=submit]")).not.toBeDisabled();
                expect(this.input).not.toHaveClass("has_error");
            });
        });

        context("when the server request fails", function() {
            beforeEach(function(){
                this.input.val("new-tag-name");
                this.dialog.$('form').submit();
                this.server.lastUpdate().failUnprocessableEntity();
            });
            it("displays a server error in the dialog", function() {
               expect(this.dialog.$(".errors")).not.toHaveClass("hidden");
            });
        });
    });
});