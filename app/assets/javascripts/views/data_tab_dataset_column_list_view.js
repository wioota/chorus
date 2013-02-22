chorus.views.DataTabDatasetColumnList = chorus.views.Base.extend({
    constructorName: "DataTabDatasetColumnListView",
    templateName:"data_tab_dataset_column_list",
    useLoadingSection:true,

    setup:function () {
        this.resource = this.collection = this.options.dataset.columns();
        this.collection.fetchAll();
    },

    postRender: function() {
        this.setupDragging();

        chorus.search({
            list: this.$('ul'),
            input: this.$('input.search')
        });
    },

    setupDragging: function() {
        this.$("li").draggable({
            cursor: "move",
            containment: "window",
            appendTo: "body",
            helper: this.dragHelper
        });
    },

    dragHelper : function(e) {
        return $(e.currentTarget).clone().addClass("drag_helper");
    },

    collectionModelContext: function(column) {
        return {
            cid: column.cid,
            fullName: column.toText(),
            type: column.get("typeClass")
        };
    }
});
