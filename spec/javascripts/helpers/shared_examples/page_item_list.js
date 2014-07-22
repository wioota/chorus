jasmine.sharedExamples.PageItemList = function () {
    describe("zzz item selection", function () {
        beforeEach(function () {
            spyOn(chorus.PageEvents, "trigger").andCallThrough();
        });

        function safeClick(target) {
            var checked = $(target).prop('checked');
            $(target).click();
            $(target).prop('checked', !checked);
        }

        function anItemIsCheckable(otherAssertions) {
            describe("And I check an item's checkbox", function () {
                var $item;

                beforeEach(function () {
                    $item = this.view.$('.item_wrapper').last();
                    var checkbox = $item.find('input[type=checkbox]');
                    safeClick(checkbox);
                });

                it("Then the item's name appears in the list of selected items", function () {
                    var event = this.view.eventName + ":checked";
                    var collection = jasmine.any(chorus.collections.Base);

                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith(event, collection);
                });

                it("Then the item is both checked and highlighted. ", function () {
                    expect($item).toHaveClass('checked');
                });

                otherAssertions && otherAssertions();
            });
        }

        context("When no items are selected", function () {
            beforeEach(function () {
                var $items = this.view.$('.item_wrapper');
                $items.each(function (i, item) {
                    var $item = $(item);
                    expect($item).not.toHaveClass('checked');
                    var checkbox = $item.find('input[type=checkbox]');
                    expect(checkbox).not.toBeChecked();
                });
            });

            anItemIsCheckable();

            describe("And I click the top level checkbox", function () {
                beforeEach(function () {
                    this.view.selectAll();
                });

                it("Then all items in the list are selected", function () {
                    var $items = this.view.$('.item_wrapper');

                    $items.each(function (i, item) {
                        expect($(item)).toHaveClass('checked');
                        
                        var checkbox = $(item).find('input[type=checkbox]');
                        expect(checkbox).toBeChecked();
                    });
                });
            });
        });

        context("When a populated proper subset of items are selected", function () {
            var $items;
            var $initiallySelectedItems;

            beforeEach(function () {
                $items = this.view.$('.item_wrapper');

                var checkbox = $items.first().find('input[type=checkbox]');

                safeClick(checkbox);
                $initiallySelectedItems = this.view.$('.item_wrapper.checked');

                expect($initiallySelectedItems.length).toBeGreaterThan(0);
                expect($initiallySelectedItems.length).toBeLessThan($items.length);
            });

            it("Then the top level checkbox is semi-filled", function () {
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith('unselectAny');
            });

            describe("And I uncheck all the selected items", function () {
                beforeEach(function () {
                    var $selectedItems = this.view.$('.item_wrapper.checked');

                    $selectedItems.each(function (i, item) {
                        var checkbox = $(item).find('input[type=checkbox]');
                        safeClick(checkbox);
                    });
                });

                it("then the top level checkbox is empty", function () {
                    expect(chorus.PageEvents.trigger).toHaveBeenCalledWith('noneSelected');
                });
            });

            describe("And I click the top-level checkbox", function () {
                beforeEach(function () {
                    chorus.PageEvents.trigger("selectNone");
                });

                it("Then all items in the list are neither checked nor highlighted.", function () {
                    var $items = this.view.$('.item_wrapper');

                    $items.each(function (i, item) {
                        var $item = $(item);
                        expect($item).not.toHaveClass('checked');
                        var checkbox = $item.find('input[type=checkbox]');
                        expect(checkbox).not.toBeChecked();
                    });
                });
            });

            anItemIsCheckable(function () {
                it("And the previously selected items remain highlighted and checked.", function () {
                    $initiallySelectedItems.each(function (i, item) {
                        expect($(item)).toHaveClass('checked');
                        
                        var checkbox = $(item).find('input[type=checkbox]');
                        expect(checkbox).toBeChecked();
                    });
                });
            });
        });

        context("When all items are selected", function () {
            beforeEach(function () {
                chorus.PageEvents.trigger.reset();

                var $allItems = this.view.$('.item_wrapper');

                $allItems.each(function (i, item) {
                    var checkbox = $(item).find('input[type=checkbox]');
                    safeClick(checkbox);
                });
            });

            it("Then the top level checkbox is checked", function () {
                expect(chorus.PageEvents.trigger).toHaveBeenCalledWith('allSelected');
            });

        });
    });
};