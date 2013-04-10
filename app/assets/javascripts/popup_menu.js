chorus.PopupMenu = (function() {
    var currentMenu;

    var releaseClicks = function() {
        $(document).unbind("click.popup_menu");
    };

    var dismissPopups = function(parentView) {
        releaseClicks();
        parentView.$(".menu").addClass("hidden");
    };

    var captureClicks = function(parentView) {
        $(document).bind("click.popup_menu", function(){ dismissPopups(parentView); });
    };

    return {
        toggle: function(parentView, selector, e) {
            if(e) {
                e.preventDefault();
                e.stopImmediatePropagation();
            }

            var previousMenu = currentMenu;
            currentMenu = parentView.$(selector);

            var isPoppedUp = !currentMenu.hasClass("hidden");
            dismissPopups(parentView);

            if (!isPoppedUp) {
                captureClicks(parentView);
            }

            if(previousMenu) {
                previousMenu.addClass("hidden");
            }

            currentMenu.toggleClass("hidden", isPoppedUp);
        },

        close: function(parentView) {
            dismissPopups(parentView);
        }
    };
})();