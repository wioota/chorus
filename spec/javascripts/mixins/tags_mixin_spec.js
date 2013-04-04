describe("chorus.Mixins.Taggable", function() {
    beforeEach(function() {
        var modelClass = Backbone.Model.include(chorus.Mixins.Taggable);
        this.model = new modelClass();
    });

    context("when the model has been loaded", function() {
        beforeEach(function() {
            this.model.loaded = true;
        });

        describe("#tags", function() {
            context("when the model doesn't have a tags array", function() {
                beforeEach(function() {
                    this.model.unset('tags');
                });

                it("returns an empty TaggingSet", function() {
                    var tags = this.model.tags();
                    expect(tags).toBeA(chorus.collections.TaggingSet);
                    expect(tags.length).toEqual(0);
                });
            });

            context("when the model has a tags array", function() {
                beforeEach(function() {
                    this.model.set('tags', [
                        {name: 'foo'},
                        {name: 'bar'}
                    ]);
                });

                it("creates a TaggingSet with the tags objects", function() {
                    var tags = this.model.tags();
                    expect(tags).toBeA(chorus.collections.TaggingSet);
                    expect(tags.length).toEqual(2);
                    expect(tags.pluck('name')).toEqual(['foo', 'bar']);
                });

                it("reuses the same tag collection on future calls", function() {
                    var originalTags = this.model.tags();
                    this.model.set('tags', [
                        {name: 'baz'}
                    ]);
                    expect(this.model.tags()).toEqual(originalTags);
                });

                it("adding a tag triggers 'change' on the model", function() {
                    spyOnEvent(this.model, "change");
                    this.model.tags().add({name: 'new-foo'});
                    expect("change").toHaveBeenTriggeredOn(this.model);
                });

                it("removing a tag triggers 'change' on the model", function() {
                    spyOnEvent(this.model, "change");
                    this.model.tags().remove(this.model.tags().at(0));
                    expect("change").toHaveBeenTriggeredOn(this.model);
                });
            });
        });

        describe("#hasTags", function() {
            context("the model has tags", function() {
                beforeEach(function() {
                    this.model.tags().reset([
                        {name: 'super_tag'}
                    ]);
                });
                it("returns true", function() {
                    expect(this.model.hasTags()).toBeTruthy();
                });
            });

            context("the model has no tags", function() {
                beforeEach(function() {
                    this.model.tags().reset([]);
                });
                it("returns false", function() {
                    expect(this.model.hasTags()).toBeFalsy();
                });
            });

            context("the model does not support tags", function() {
                it("returns false", function() {
                    expect(this.model.hasTags()).toBeFalsy();
                });
            });
        });
    });

    context("when the model has not been loaded", function() {
        describe("#tags", function() {
            beforeEach(function() {
                this.model.set('tags', [
                    {name: 'foo'}
                ]);
            });

            it("returns an empty TaggingSet", function() {
                var tags = this.model.tags();
                expect(tags).toBeA(chorus.collections.TaggingSet);
                expect(tags.length).toEqual(0);
            });

            context("when the model is loaded after tags has been used", function() {
                beforeEach(function() {
                    this.model.tags();
                    this.model.set('tags', [
                        {name: 'bar'}, {name: 'baz'}
                    ]);
                    this.model.loaded = true;
                });

                it("uses the newly loaded tags", function() {
                    expect(this.model.tags().length).toEqual(2);
                });
            });
        });
    });

    describe("#updateTags", function() {
        beforeEach(function() {
            this.model = rspecFixtures.workfile.sql({id: "123", tags: [
                {name: "tag1"},
                {name: "tag2"}
            ]});
            this.fakeTaggingsUpdater = new chorus.models.TaggingsUpdater();
            spyOn(this.fakeTaggingsUpdater, "updateTags");
            spyOn(chorus.models, "TaggingsUpdater").andReturn(this.fakeTaggingsUpdater);
        });

        it("add and saves tags", function() {
            this.tag = new chorus.models.Tag({name: 'foo'});
            this.model.updateTags({add: this.tag});

            expect(chorus.models.TaggingsUpdater).toHaveBeenCalled();
            var initializerArg = chorus.models.TaggingsUpdater.mostRecentCall.args[0];

            expect(initializerArg.collection.length).toEqual(1);
            expect(initializerArg.collection.at(0)).toEqual(this.model);
            expect(this.fakeTaggingsUpdater.updateTags).toHaveBeenCalledWith({add: this.tag});
        });

        it("removes and saves tags", function() {
            this.tag = new chorus.models.Tag({name: 'foo'});
            this.model.updateTags({remove: this.tag});

            expect(chorus.models.TaggingsUpdater).toHaveBeenCalled();
            var initializerArg = chorus.models.TaggingsUpdater.mostRecentCall.args[0];

            expect(initializerArg.collection.length).toEqual(1);
            expect(initializerArg.collection.at(0)).toEqual(this.model);
            expect(this.fakeTaggingsUpdater.updateTags).toHaveBeenCalledWith({remove: this.tag});
        });
    });
});