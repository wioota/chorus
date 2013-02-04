describe("textext extensions", function() {
    describe("Ajax onComplete", function() {
        beforeEach(function() {
            this.textarea = $('<textarea></textarea>');
            this.tagSet = new chorus.collections.TaggingSet();
            this.textarea.textext({
                plugins: 'ajax',
                ajax: {
                    existingTagCollection: this.tagSet
                }
            });
            this.textext = this.textarea.textext()[0];
        });

        it("pulls the response object out of the JSON data", function() {
            var setSuggestions = jasmine.createSpy('setSuggestions');
            this.textarea.on('setSuggestions', setSuggestions);
            this.textext.ajax().onComplete({response: [{name: 'foo'}]}, 'bar');
            expect(setSuggestions).toHaveBeenCalledWith(jasmine.any(Object), {result: [{name: 'foo'}]});
        });

        it("removes tags already in the tag set", function() {
            this.tagSet.add({name: 'foo'});
            var setSuggestions = jasmine.createSpy('setSuggestions');
            this.textarea.on('setSuggestions', setSuggestions);
            this.textext.ajax().onComplete({response: [{name: 'foo'}, {name: 'bar'}]}, 'bar');
            expect(setSuggestions).toHaveBeenCalledWith(jasmine.any(Object), {result: [{name: 'bar'}]});
        });
    });

    describe("getFormData", function() {
        beforeEach(function() {
            this.triggerSpy = jasmine.createSpy('triggerSpy');

            var self = this;
            this.context = {
                getWeightedEventResponse: function () {
                    return {
                        input: self.input,
                        form: []
                    };
                },
                trigger: this.triggerSpy
            };

            this.getFormData = $.fn.textext.TextExt.prototype.getFormData;
        });

        context("when the user enters an arbitrary character", function() {
            beforeEach(function() {
                this.input = "abc";
            });

            it("does not push a new tag", function() {
                $.proxy(this.getFormData, this.context)();

                expect(this.triggerSpy).toHaveBeenCalledWith('setFormData', []);
                expect(this.triggerSpy).toHaveBeenCalledWith('setInputData', 'abc');
            });
        });

        context("when the user enters a comma", function() {
            beforeEach(function() {
                this.input = "abc,";
            });

            it("pushes the new tag to the form", function() {
                $.proxy(this.getFormData, this.context)();

                expect(this.triggerSpy).toHaveBeenCalledWith('setFormData', [
                    {name: 'abc'}
                ]);
                expect(this.triggerSpy).toHaveBeenCalledWith('setInputData', '');
            });
        });
    });
});