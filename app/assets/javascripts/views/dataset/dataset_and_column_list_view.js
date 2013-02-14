chorus.views.DatasetAndColumnList = chorus.views.Base.extend({
    templateName: "dataset_and_column_list",
    constructorName: 'DatasetAndColumnList',

    subviews: {
        ".data_tab": "datasetList",
        ".database_column_list": "columnList"
    },

    setup: function() {
        this.datasetList = new chorus.views.DataTab({ schema: this.model });
        this.columnList = new chorus.views.DatabaseColumnSidebarList({ schema: this.model });

        this.subscribePageEvent("datasetSelected", function(tableOrView) {
            this.$(".database_column_list").removeClass("hidden");
            this.$(".data_tab").addClass("hidden");
        });

        this.bindings.add(this.columnList, "back", function() {
            this.$("input.search").val("");
            this.$(".data_tab").removeClass("hidden");
            this.$(".database_column_list").addClass("hidden");
            chorus.PageEvents.broadcast("dataset:back");
        });
    }
});
