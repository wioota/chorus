describe("chorus.views.WorkfileContentDetails", function() {
    beforeEach(function() {
        this.model = rspecFixtures.workfile.sql();
        this.model.workspace().set({ archivedAt: null });
    });

    describe(".buildFor", function() {
        context("when the given workfile is an image", function() {
            beforeEach(function() {
                this.model = rspecFixtures.workfile.image();
            });

            it("instantiates an ImageWorkfileContentDetails view with the given workfile", function() {
                var contentDetails = chorus.views.WorkfileContentDetails.buildFor(this.model);
                expect(contentDetails).toBeA(chorus.views.ImageWorkfileContentDetails);
            });
        });

        context("when the given workfile is a SQL file", function() {
            beforeEach(function() {
                this.model = rspecFixtures.workfile.sql();
            });

            context("when its workspace is active (not archived)", function() {
                context("when the workspace is updateable", function() {
                    beforeEach(function() {
                        spyOn(this.model.workspace(), 'canUpdate').andReturn(true);
                        spyOn(this.model.workspace(), 'isActive').andReturn(true);
                    });

                    it("instantiates a SqlWorkfileContentDetails view", function() {
                        var contentDetails = chorus.views.WorkfileContentDetails.buildFor(this.model);
                        expect(contentDetails).toBeA(chorus.views.SqlWorkfileContentDetails);
                    });
                });
                context("when the workspace is not updateable", function() {
                    beforeEach(function() {
                        spyOn(this.model.workspace(), 'canUpdate').andReturn(false);
                    });

                    it("instantiates a ReadOnlyWorkfileContentDetails", function() {
                        var contentDetails = chorus.views.WorkfileContentDetails.buildFor(this.model);
                        expect(contentDetails).toBeA(chorus.views.SqlWorkfileContentDetails);
                    });
                });
            });

            context("when its workspace is archived", function() {
                it("instantiates a ArchivedWorkfileContentDetails view", function() {
                    spyOn(this.model.workspace(), 'isActive').andReturn(false);
                    var contentDetails = chorus.views.WorkfileContentDetails.buildFor(this.model);
                    expect(contentDetails).toBeA(chorus.views.ArchivedWorkfileContentDetails);
                });
            });
        });

        context("when the given workfile is an Alpine file", function() {
            beforeEach(function() {
                this.model = rspecFixtures.workfile.binary({ fileType: "alpine" });
                spyOn(chorus.views, "AlpineWorkfileContentDetails");
                this.view = chorus.views.WorkfileContentDetails.buildFor(this.model);
            });

            it("instantiates an AlpineWorkfileContentDetails view", function() {
                expect(this.view).toBeA(chorus.views.AlpineWorkfileContentDetails);
            });
        });

        context("when the given workfile is an Tableau file", function() {
            beforeEach(function() {
                this.model = rspecFixtures.workfile.tableau();
                spyOn(chorus.views, "TableauWorkfileContentDetails");
                this.view = chorus.views.WorkfileContentDetails.buildFor(this.model);
            });

            it("instantiates an TableauWorkfileContentDetails view", function() {
                expect(this.view).toBeA(chorus.views.TableauWorkfileContentDetails);
            });
        });

        context("when the workfile is a binary file", function() {
            beforeEach(function() {
                this.model = rspecFixtures.workfile.binary();
                this.view = chorus.views.WorkfileContentDetails.buildFor(this.model);
            });

            it("instantiates a BinaryWorkfileContentDetails view", function() {
                expect(this.view).toBeA(chorus.views.BinaryWorkfileContentDetails);
            });
        });

        context("when given anything else", function() {
            beforeEach(function() {
                this.model = rspecFixtures.workfile.text();
                this.view = chorus.views.WorkfileContentDetails.buildFor(this.model);
            });

            it("instantiates an WorkfileContentDetails view", function() {
                expect(this.view).toBeA(chorus.views.WorkfileContentDetails);
            });
        });
    });

    describe("custom scrolling", function() {
        beforeEach(function() {
            this.model = rspecFixtures.workfile.text();
            this.view = chorus.views.WorkfileContentDetails.buildFor(this.model);
            spyOn(this.view, "scrollHandler");
            this.view.render();
        });
        it("handles scrolling (to anchor content details to the top of the window when scrolling down)", function() {
            $(window).trigger("scroll");
            expect(this.view.scrollHandler).toHaveBeenCalled();
        });
        it("only binds scroll handling once", function() {
            this.view.render();
            this.view.render();
            $(window).trigger("scroll");
            expect(this.view.scrollHandler.callCount).toBe(1);
        });
    });

    describe("#render", function() {
        beforeEach(function() {
            this.saveFileMenu = stubQtip(".save_as");
            this.view = new chorus.views.WorkfileContentDetails({model: this.model});
            this.view.render();
        });

        it("has the save_as button in the details bar", function() {
            expect(this.view.$("button.save_as").length).toBe(1);
            expect(this.view.$("button.save_as")).toContainTranslation('workfile.content_details.save_as');
        });

        it("should not have disabled class from the save as link", function() {
            expect(this.view.$(".save_as")).not.toBeDisabled();
        });

        it("should not display the autosave text", function() {
            expect(this.view.$("span.auto_save")).toHaveClass("hidden");
        });

        context("menus", function() {
            it("when replacing the current version, it should broadcast the file:replaceCurrentVersion event", function() {
                spyOn(chorus.PageEvents, "broadcast");
                this.view.replaceCurrentVersion();
                expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith("file:replaceCurrentVersion");
            });

            it("when creating a new version, it should broadcast the file:createNewVersion event", function() {
                spyOn(chorus.PageEvents, "broadcast");
                this.view.createNewVersion();
                expect(chorus.PageEvents.broadcast).toHaveBeenCalledWith("file:createNewVersion");
            });
        });

        context("when the workspace is archived", function() {
            beforeEach(function() {
                this.model.workspace().set({ archivedAt: "2012-05-08 21:40:14" });
                this.view.render();
            });

            it("should disable the save button", function() {
                expect(this.view.$(".save_as")).toBeDisabled();
            });
        });

        context("when user is editing the file", function() {
            context("and the autosave event is fired", function() {
                beforeEach(function() {
                    chorus.PageEvents.broadcast("file:autosaved");
                });

                it("should display the autosave text", function() {
                    expect(this.view.$("span.auto_save")).not.toHaveClass("hidden");
                });

                context("and the save as current button is clicked", function() {
                    beforeEach(function() {
                        this.view.$(".save_as").click();
                        this.saveFileMenu.find('a[data-menu-name="replace"]').click();
                    });

                    it("should display the 'Saved at' text", function() {
                        expect(this.view.$("span.auto_save").text()).toContain("Saved at");
                    });
                });
            });

            context("when the user clicks on the 'save as' button", function() {
                context("when the workfile is the most recent version", function() {
                    beforeEach(function() {
                        this.view.render();
                        this.view.$(".save_as").click();
                    });

                    it("displays the tooltip", function() {
                        expect(this.saveFileMenu).toHaveVisibleQtip();
                    });

                    it("renders the menu links", function() {
                        expect(this.saveFileMenu).toContainTranslation("workfile.content_details.replace_current");
                        expect(this.saveFileMenu).toContainTranslation("workfile.content_details.save_new_version");
                        expect(this.saveFileMenu.find("a")).not.toHaveAttr("disabled");
                    });
                });

                context("when the workfile is not the most recent version", function() {
                    beforeEach(function() {
                        this.view.model.set({ versionInfo: { id: 1 }, latestVersionId: 2 });
                        this.view.render();
                        this.view.$(".save_as").click();
                    });

                    it("displays the tooltip", function() {
                        expect(this.saveFileMenu).toHaveVisibleQtip();
                    });

                    it("disables the link to replace version", function() {
                        expect(this.saveFileMenu.find("a[data-menu-name='replace']")).toHaveAttr("disabled");
                    });
                });
            });
        });
    });

    describe("#formatTime", function() {
        beforeEach(function() {
            this.view = new chorus.views.WorkfileContentDetails(this.model);
        });

        it("should format the time in the AM", function() {
            var date = new Date(1325876400 * 1000);
            expect(this.view.formatTime(date)).toBe("11:00 AM");
        });

        it("should format the time in the PM", function() {
            var date = new Date(1325908800 * 1000);
            expect(this.view.formatTime(date)).toBe("8:00 PM");
        });

        it("should format the time if it is Noon/Midnight", function() {
            var date = new Date(1325880000 * 1000);
            expect(this.view.formatTime(date)).toBe("12:00 PM");

            date = new Date(1325836800 * 1000);
            expect(this.view.formatTime(date)).toBe("12:00 AM");
        });
    });
});
