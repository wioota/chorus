describe('chorus.handlebarsHelpers.user', function() {
    describe("ifAdmin", function () {
        beforeEach(function () {
            this.ifAdminSpy = jasmine.createSpy();
            this.ifAdminSpy.inverse = jasmine.createSpy();
        });

        describe("when the user is an admin", function () {
            beforeEach(function () {
                setLoggedInUser({ admin:true });
            });

            it("executes the block", function () {
                Handlebars.helpers.ifAdmin(this.ifAdminSpy);
                expect(this.ifAdminSpy).toHaveBeenCalled();
                expect(this.ifAdminSpy.inverse).not.toHaveBeenCalled();
            });
        });

        describe("when the user is not an admin", function () {
            beforeEach(function () {
                setLoggedInUser({ admin:false });
            });

            it("does not execute the block", function () {
                Handlebars.helpers.ifAdmin(this.ifAdminSpy);
                expect(this.ifAdminSpy.inverse).toHaveBeenCalled();
                expect(this.ifAdminSpy).not.toHaveBeenCalled();
            });
        });

        describe("when chorus.user is undefined", function () {
            beforeEach(function () {
                unsetLoggedInUser();
            });

            it("does not execute the block", function () {
                Handlebars.helpers.ifAdmin(this.ifAdminSpy);
                expect(this.ifAdminSpy.inverse).toHaveBeenCalled();
                expect(this.ifAdminSpy).not.toHaveBeenCalled();
            });
        });
    });

    describe("#ifAdminOr", function () {
        beforeEach(function () {
            this.ifAdminOrSpy = jasmine.createSpy();
            this.ifAdminOrSpy.inverse = jasmine.createSpy();
        });

        context("when the user is an admin", function () {
            beforeEach(function () {
                setLoggedInUser({ admin:true });
            });

            it("executes the block", function () {
                Handlebars.helpers.ifAdminOr(false, this.ifAdminOrSpy);
                expect(this.ifAdminOrSpy).toHaveBeenCalled();
                expect(this.ifAdminOrSpy.inverse).not.toHaveBeenCalled();
            });
        });

        context("when user is not an admin", function () {
            beforeEach(function () {
                setLoggedInUser({ admin:false });
            });

            it("executes the block when the flag is true", function () {
                Handlebars.helpers.ifAdminOr(true, this.ifAdminOrSpy);
                expect(this.ifAdminOrSpy).toHaveBeenCalled();
                expect(this.ifAdminOrSpy.inverse).not.toHaveBeenCalled();
            });

            it("executes the inverse block when the flag is false", function () {
                Handlebars.helpers.ifAdminOr(false, this.ifAdminOrSpy);
                expect(this.ifAdminOrSpy).not.toHaveBeenCalled();
                expect(this.ifAdminOrSpy.inverse).toHaveBeenCalled();
            });
        });
    });

    describe("ifCurrentUserNameIs", function () {
        beforeEach(function () {
            setLoggedInUser({ username:"benjamin" });
            this.spy = jasmine.createSpy("ifCurrentUserNameIs");
            this.spy.inverse = jasmine.createSpy("ifCurrentUserNameIs inverse");
        });

        describe("when the given username matches the current user's name'", function () {
            it("executes the block", function () {
                Handlebars.helpers.ifCurrentUserNameIs("benjamin", this.spy);
                expect(this.spy).toHaveBeenCalled();
                expect(this.spy.inverse).not.toHaveBeenCalled();
            });
        });

        describe("when the given username does NOT match the current user's name", function () {
            it("execute the inverse block", function () {
                Handlebars.helpers.ifCurrentUserNameIs("noe valley", this.spy);
                expect(this.spy.inverse).toHaveBeenCalled();
                expect(this.spy).not.toHaveBeenCalled();
            });
        });

        describe("when chorus.user is undefined", function () {
            beforeEach(function () {
                unsetLoggedInUser();
            });

            it("executes the inverse block", function () {
                Handlebars.helpers.ifCurrentUserNameIs("superman", this.spy);
                expect(this.spy.inverse).toHaveBeenCalled();
                expect(this.spy).not.toHaveBeenCalled();
            });
        });
    });

    describe("currentUserName", function () {
        beforeEach(function () {
            this.template = "{{currentUserName}}";
            chorus.session.set({username:"bob"});
        });
        it("should return the user", function () {
            expect(Handlebars.compile(this.template)({})).toBe(chorus.session.get("username"));
        });
    });

    describe("displayNameFromPerson", function () {
        it("renders the fullname", function () {
            expect(Handlebars.helpers.displayNameFromPerson({firstName:"EDC", lastName:"Admin"})).toBe("EDC Admin");
        });
    });
});