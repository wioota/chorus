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
            this.suggestionSpy = jasmine.createSpy('setSuggestions');
            this.textarea.on('setSuggestions', this.suggestionSpy);
        });

        it("pulls the response object out of the JSON data", function() {
            this.textext.ajax().onComplete({response: [{name: 'foo'}]}, 'bar');
            expect(this.suggestionSpy).toHaveBeenCalledWith(jasmine.any(Object), {result: [{suggestionText: 'bar (' + t("tags.create_new") + ')', name: 'bar'}, {name: 'foo'}]});
        });

        it("removes tags already in the tag set", function() {
            this.tagSet.add({name: 'foo'});
            this.textext.ajax().onComplete({response: [{name: 'foo'}, {name: 'bar'}]}, 'bar');
            expect(this.suggestionSpy).toHaveBeenCalledWith(jasmine.any(Object), {result: [{name: 'bar'}]});
        });

        context("when the query tag is already in the autocomplete response", function() {
            it("does not display the query tag twice in the list", function() {
                this.textext.ajax().onComplete({response: [{name: 'bar'}]}, 'bar');
                expect(this.suggestionSpy).toHaveBeenCalledWith(jasmine.any(Object), {result: [{name: 'bar'}]});
            });
        });

        context("when the query tag is empty", function(){
           it("does not suggest (Create new)", function(){
               this.textext.ajax().onComplete({response: [{name: 'bar'}]}, '');
               expect(this.suggestionSpy).toHaveBeenCalledWith(jasmine.any(Object), {result: [{name: 'bar'}]});
           });
        });

        context("when the query tag is not in the autocomplete response", function() {
            it("adds the current value with (Create New) to the beginning of the list", function() {
                this.textext.ajax().onComplete({response: []}, 'bar');
                expect(this.suggestionSpy).toHaveBeenCalledWith(jasmine.any(Object), {result: [{suggestionText: 'bar (' + t("tags.create_new") + ')', name: 'bar'}]});
            });
        });
    });
});