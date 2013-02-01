chorus.views.SchemaListSidebar = chorus.views.Sidebar.extend({
    templateName: "schema_list_sidebar",

    setup: function() {
        this.subscribePageEvent("schema:selected", this.setSchema);
        this.subscribePageEvent("schema:deselected", this.unsetSchema);
    },

    setSchema: function(schema) {
        this.resource = schema;
        this.render();
    },

    unsetSchema: function() {
        delete this.resource;
        this.render();
    }
});
