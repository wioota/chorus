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

    describe("#accountForUser", function() {
        beforeEach(function() {
            this.user = rspecFixtures.user();
            this.account = this.instance.accountForUser(this.user);
        });

        it("returns an InstanceAccount", function() {
            expect(this.account).toBeA(chorus.models.InstanceAccount);
        });

        it("sets the instance id", function() {
            expect(this.account.get("instanceId")).toBe(this.instance.get("id"));
        });

        it("sets the user id based on the given user", function() {
            expect(this.account.get("userId")).toBe(this.user.get("id"));
        });
    });

    describe("#accountForCurrentUser", function() {
        beforeEach(function() {
            this.currentUser = rspecFixtures.user();
            setLoggedInUser(this.currentUser.attributes);
        });

        it("memoizes", function() {
            var account = this.instance.accountForCurrentUser();
            expect(account).toBe(this.instance.accountForCurrentUser());
        });

        context("when the account is destroyed", function() {
            it("un-memoizes the account", function() {
                var previousAccount = this.instance.accountForCurrentUser();
                previousAccount.trigger("destroy");

                var account = this.instance.accountForCurrentUser();
                expect(account).not.toBe(previousAccount);
            });

            it("triggers 'change' on the instance", function() {
                spyOnEvent(this.instance, 'change');
                this.instance.accountForCurrentUser().trigger("destroy");
                expect("change").toHaveBeenTriggeredOn(this.instance);
            });
        });
    });

    describe("#accountForOwner", function() {
        beforeEach(function() {
            var owner = this.owner = this.instance.owner();
            this.accounts = rspecFixtures.instanceAccountSet();
            this.accounts.each(function(account) {
                account.set({
                    owner: {
                        id: owner.id + 1
                    }
                });
            });

            this.accounts.models[1].set({owner: this.owner.attributes});
            spyOn(this.instance, "accounts").andReturn(this.accounts);
        });

        it("returns the account for the owner", function() {
            expect(this.instance.accountForOwner()).toBeA(chorus.models.InstanceAccount);
            expect(this.instance.accountForOwner()).toBe(this.accounts.models[1]);
        });
    });

    describe("#accounts", function() {
        beforeEach(function() {
            this.instanceAccounts = this.instance.accounts();
        });

        it("returns an InstanceAccountSet", function() {
            expect(this.instanceAccounts).toBeA(chorus.collections.InstanceAccountSet);
        });

        it("sets the instance id", function() {
            expect(this.instanceAccounts.attributes.instanceId).toBe(this.instance.get('id'));
        });

        it("memoizes", function() {
            expect(this.instanceAccounts).toBe(this.instance.accounts());
        });
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

    describe("#usage", function() {
        beforeEach(function() {
            this.instanceUsage = this.instance.usage();
        });

        it("returns an InstanceUsage object", function() {
            expect(this.instanceUsage).toBeA(chorus.models.InstanceUsage);
        });

        it("sets the instance id", function() {
            expect(this.instanceUsage.attributes.instanceId).toBe(this.instance.get('id'));
        });

        it("memoizes", function() {
            expect(this.instanceUsage).toBe(this.instance.usage());
        });
    });

    describe("#isGreenplum", function() {
        it("returns true for gpdb instances", function() {
            expect(this.instance.isGreenplum()).toBeTruthy();
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
                    maintenanceDb: "postgres",
                    provision_type: "register"
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
    });

    describe("#hasWorkspaceUsageInfo", function() {
        it("returns true when the instance's usage is loaded", function() {
            this.instance.usage().set({workspaces: []});
            expect(this.instance.hasWorkspaceUsageInfo()).toBeTruthy();
        });

        it("returns false when the instances's usage is not loaded", function() {
            this.instance.usage().unset("workspaces");
            expect(this.instance.hasWorkspaceUsageInfo()).toBeFalsy();
        });
    });

    describe("#sharing", function() {
        it("returns an instance sharing model", function() {
            expect(this.instance.sharing().get("instanceId")).toBe(this.instance.get("id"));
        });

        it("caches the sharing model", function() {
            var originalModel = this.instance.sharing();
            expect(this.instance.sharing()).toBe(originalModel);
        });
    });

    describe("#sharedAccountDetails", function() {
        beforeEach(function() {
            this.owner = this.instance.owner();
            this.accounts = rspecFixtures.instanceAccountSet();
            this.accounts.models[1].set({owner: this.owner.attributes});
            spyOn(this.instance, "accounts").andReturn(this.accounts);
        });

        it("returns the account name of the user who owns the instance and shared it", function() {
            this.user = rspecFixtures.user();
            this.account = this.instance.accountForUser(this.user);
            expect(this.instance.sharedAccountDetails()).toBe(this.instance.accountForOwner().get("dbUsername"));
        });
    });

    describe("#providerIconUrl", function() {
        it("returns the right url for gpdb instances", function() {
            expect(this.instance.providerIconUrl()).toBe("/images/instances/icon_datasource_greenplum.png");
        });
    });
});
