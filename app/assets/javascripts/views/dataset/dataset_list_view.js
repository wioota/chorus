//= require views/layout/page_item_list_view

chorus.views.DatasetList = chorus.views.PageItemList.extend({
    eventName: "dataset",
    constructorName: "DatasetListView",
    useLoadingSection: true,

    setup: function() {
        this.options.entityType = "dataset";
        this.options.entityViewType = chorus.views.DatasetItem;
        this.options.listItemOptions = {
            hasActiveWorkspace: this.options.hasActiveWorkspace
        };

        this._super("setup", arguments);
    },

    postRender: function() {
        var $list = this.$el;
        if(this.collection.length === 0 && this.collection.loaded) {
            var linkText = Handlebars.helpers.linkTo("#/data_sources", t("dataset.browse.linkText"));
            var noDatasetEl = $("<div class='browse_more'></div>");

// TODO: add fuincationality so that the empty data message displays using the app standard empty box
//             var emptyStateEl = $("<div class="empty_state"></div>");
//             var emptyStateTitle = $("<div class="empty_message"></div>");
//             var emptyStateTip = $("<div class="text_tip"></div>");
            
//                    <div class="empty_message">
//                       {{t "dashboard.recent_workfiles.empty.message"}}
//                     </div>
//                     <div class="text_tip">
//                         {{t "dashboard.recent_workfiles.empty.tip"}}
//                     </div>


            var hintText;
            if (this.collection.hasFilter && this.collection.hasFilter()) {
                // empty filtered list
                hintText = t("dataset.filtered_empty");
            } else if (this.collection.attributes.workspaceId) {
                // empty workspace
                hintText = t("dataset.browse_more_workspace", {linkText: linkText});
            } else {
                // empty datasets in schema?
                hintText = t("dataset.browse_more_data_source", {linkText: linkText});
            }

            noDatasetEl.append(hintText);
            $list.append(noDatasetEl);
        }

        this._super("postRender", arguments);
    }
});
