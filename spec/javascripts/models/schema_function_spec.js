describe("chorus.models.SchemaFunction", function() {
    beforeEach(function() {
        this.model = new chorus.models.SchemaFunction({
            schemaName: "aa",
            name: "fun",
            returnType: "void",
            language: "sql",
            argNames: ["elephant", ""],
            argTypes: ["Int", "Bool"]})
    })
    describe("#toText", function() {
        context("with lowercase names", function() {
            it("formats the string to put into the sql editor", function() {
                expect(this.model.toText()).toBe('aa.fun(Int elephant, Bool arg2)');
            });
        });
        context("with uppercase letters in the names", function() {
            beforeEach(function() {
                this.model.set({schemaName: "Aa", name: "fuN"});
            })
            it("puts quotes around the uppercase names", function() {
                expect(this.model.toText()).toBe('"Aa"."fuN"(Int elephant, Bool arg2)');
            });
        })

    });
    describe("#toHintText", function() {
        it("formats the string correctly", function() {
            expect(this.model.toHintText()).toBe("void fun(Int elephant, Bool arg2)")
        })
    })
})