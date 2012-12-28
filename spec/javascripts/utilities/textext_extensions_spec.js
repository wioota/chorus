describe("textext extensions", function() {
    describe("Ajax onComplete", function() {
        beforeEach(function() {
            this.textarea = $('<textarea></textarea>');
            this.tagSet = new chorus.collections.TagSet();
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
});