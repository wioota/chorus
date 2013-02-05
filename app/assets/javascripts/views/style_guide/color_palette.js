(function () {
    var colors = {
        "$body-background-color": "#EAEFF6",
        "$body-glow-color ": "#C8DCED",
        "$shaded-background-color": "#E1E5E9",
        "$data-table-background-color": "#EAEEF2",
        "$dialog-background-color": "white",
        "$element-background": "white",
        "$button-background-color ": "white",
        "$list-hover-color": "#e3e8ed",
        "$list-checked-color": "#dde3e9",
        "$progress-bar-background-color ": "#D8DEE6",
        "$progress-bar-full-background-color ": "#AE0020",
        "$administrator-background-color": "#5f5f5f",
        "$search-highlight-color": "#FFFF00",
        "$error-background-color": "#B61B1D",
        "$alert-background-color": "#B5121B",
        "$content-details-action-background-color": "#B3D988",
        "$content-details-create-background-color": "#49A942",
        "$content-details-chart-icon-hover-background-color": "#C3ECA0",
        "$content-details-chart-icon-selected-background-color": "#42AA3D",
        "$content-details-info-bar-background-color": "#C4DCEB",
        "$picklist-selected-background-color": "#3795DD",
        "$activity-stream-comment-background-color": "#DFE5EB",
        "$selected-row-hover-background-color": "#DCE2E8",
        "$chart-fill-color": "#4A83C3",
        "$dataset-number-background-color": "#788DA5",
        "$ie-header-color": "#c7c7c7",
        "$tab-gradient-color ": "#D5E0EB"
    };

    chorus.views.ColorPaletteView = chorus.views.Base.extend({
        constructorName: "StyleGuideColorPaletteView",
        templateName:"style_guide_color_palette",

        context:function () {
            return { colors: colors };
        }
    });
})();