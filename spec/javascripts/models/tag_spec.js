describe("chorus.models.tag", function() {
    describe('#matches', function(){
        beforeEach(function(){
           this.tag = new chorus.models.Tag({name: 'foo'});
        });

        it("compares tag names ignoring case", function() {
            expect(this.tag.matches('foo')).toBe(true);
            expect(this.tag.matches('FOO')).toBe(true);
            expect(this.tag.matches('baz')).toBe(false);
        });

        it('compares tags ignoring leading/trailing spaces', function(){
            expect(this.tag.matches(' foo ')).toBe(true);
        });
    });
});