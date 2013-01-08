describe("chorus.models.OracleInstance", function() {
    beforeEach(function() {
        // TODO: generate real oracle fixture
        this.instance = new chorus.models.OracleInstance(rspecFixtures.gpdbInstance({
            id: 1,
            entityType: "oracle_instance"
        }));
        this.instance.set('dbName', 'RockinDB');
    });

    it("has the right entity type", function() {
        expect(this.instance.entityType).toBe("oracle_instance");
    });

    it("has the right show url", function() {
        expect(this.instance.showUrl()).toBe("#/instances/1/schemas");
    });

    it("has a valid url", function() {
        expect(this.instance.url()).toBe("/oracle_instances/" + this.instance.get('id'));
    });

    describe("#isGreenplum", function() {
        it("returns false for oracle instances", function() {
            expect(this.instance.isGreenplum()).toBeFalsy();
        });
    });

    describe("validations", function() {
        context("with a registered instance", function() {
            beforeEach(function() {
                this.attrs = {
                    name: "foo",
                    host: "gillette",
                    dbUsername: "dude",
                    dbPassword: "whatever",
                    port: "1234",
                    dbName: "foo",
                    provision_type: "register" //FIXME
                };
            });

            context("when the instance is new", function() {
                beforeEach(function() {
                    this.instance.unset("id", { silent: true });
                });

                it("returns true when the model is valid", function() {
                    expect(this.instance.performValidation(this.attrs)).toBeTruthy();
                });

                _.each(["name", "host", "dbUsername", "dbPassword", "port", "dbName"], function(attr) {
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
    });

    describe("#providerIconUrl", function() {
        it("returns the right url for oracle instances", function() {
            expect(this.instance.providerIconUrl()).toBe("/images/instances/icon_datasource_oracle.png");
        });
    });
});
