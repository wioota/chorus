describe("chorus.models.GpdbInstance", function() {
    beforeEach(function() {
        this.instance = rspecFixtures.gpdbInstance({id: 1});
    });

    it("has the right entity type", function() {
        expect(this.instance.entityType).toBe("gpdb_instance");
    });

    it("has the right show url", function() {
        expect(this.instance.showUrl()).toBe("#/instances/1/databases");
    });

    it("has the right url", function() {
        expect(this.instance.url()).toContain('/data_sources/1');

        this.instance.unset("id", { silent: true });
        expect(this.instance.url()).toBe('/data_sources/');
    });

    it('has the type', function() {
        expect(this.instance.get('type')).toBe('GREENPLUM');
    });

    describe("#databases", function() {
        beforeEach(function() {
            this.databases = this.instance.databases();
        });

        it("returns an DatabaseSet", function() {
            expect(this.databases).toBeA(chorus.collections.DatabaseSet);
        });

        it("sets the instance id", function() {
            expect(this.databases.attributes.instanceId).toBe(this.instance.get('id'));
        });

        it("memoizes", function() {
            expect(this.databases).toBe(this.instance.databases());
        });
    });

    describe("validations", function() {
        beforeEach(function() {
            this.attrs = {
                name: "foo",
                host: "gillette",
                dbUsername: "dude",
                dbPassword: "whatever",
                port: "1234",
                maintenanceDb: "postgres"
            };
        });

        context("when the instance is new", function() {
            beforeEach(function() {
                this.instance.unset("id", { silent: true });
            });

            it("returns true when the model is valid", function() {
                expect(this.instance.performValidation(this.attrs)).toBeTruthy();
            });

            _.each(["name", "host", "dbUsername", "dbPassword", "port", "maintenanceDb"], function(attr) {
                it("requires " + attr, function() {
                    this.attrs[attr] = "";
                    expect(this.instance.performValidation(this.attrs)).toBeFalsy();
                    expect(this.instance.errors[attr]).toBeTruthy();
                });
            });

            it("allows name with spaces", function() {
                this.attrs.name = "foo bar";
                expect(this.instance.performValidation(this.attrs)).toBeTruthy();
            });

            it("requires name with valid length", function() {
                this.attrs.name = "testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest";
                expect(this.instance.performValidation(this.attrs)).toBeFalsy();
                expect(this.instance.errors.name).toMatchTranslation("validation.required_pattern", {fieldName: t('instances.dialog.instance_name')});
            });

            it("requires valid port", function() {
                this.attrs.port = "z123";
                expect(this.instance.performValidation(this.attrs)).toBeFalsy();
                expect(this.instance.errors.port).toBeTruthy();
            });
        });

        context("when the instance has already been created", function() {
            it("does not require a dbUsername or dbPassword", function() {
                delete this.attrs.dbPassword;
                delete this.attrs.dbUsername;
                expect(this.instance.performValidation(this.attrs)).toBeTruthy();
            });
        });
    });

    describe("#providerIconUrl", function() {
        it("returns the right url for gpdb instances", function() {
            expect(this.instance.providerIconUrl()).toBe("/images/instances/icon_gpdb_instance.png");
        });
    });
});
