chorus.views.DataTable = chorus.views.Base.extend({
    templateName: "data_table",
    constructorName: "DataTable",

    // backbone events don't work for scroll?!
    postRender: function() {
        this.$(".tbody").bind("scroll", _.bind(this.adjustHeaderPosition, this));

        this.setupScrolling(".tbody");
        this.setupResizability();
    },

    setupResizability: function() {
        this.$('.th:first').resizable({
            autoHide: true,
            handles: "e",
            alsoResize: ".column:first"
        });
    },

    additionalContext: function() {
        return {
            shuttle: this.options.shuttle === undefined || this.options.shuttle,
            columns: this.model.columnOrientedData()
        };
    },

    adjustHeaderPosition: function() {
        this.$(".thead").css({ "left": -this.scrollLeft() });
    },

    scrollLeft: function() {
        var api = this.$(".tbody").data("jsp");
        return api && api.getContentPositionX();
    }
});