describe("chorus.models.tag", function() {
    beforeEach(function(){
        this.tag = new chorus.models.Tag({name: 'foo'});
    });
    describe('#matches', function(){
        it("compares tag names ignoring case", function() {
            expect(this.tag.matches('foo')).toBe(true);
            expect(this.tag.matches('FOO')).toBe(true);
            expect(this.tag.matches('baz')).toBe(false);
        });

        it('compares tags ignoring leading/trailing spaces', function(){
            expect(this.tag.matches(' foo ')).toBe(true);
        });
    });

    describe("#showUrlTemplate", function() {
        it("shows the URL for the tag", function() {
            expect(this.tag.showUrl()).toBe("#/tags/" + this.tag.name());
        });

        describe("when the tag name has special characters", function() {
            beforeEach(function() {
                this.tag.set({ name: '!@#$%^&*()"'});
            });

            it('uri encodes the url', function() {
                expect(this.tag.showUrl()).toEqual('#/tags/!@%23$%25%5E&*()%22');
            });
        });
    });
});