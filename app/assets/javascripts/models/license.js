chorus.models.License = chorus.models.Base.extend({
    constructorName: "License",

    limitWorkspaceMembership: function() {
        return this.get("limitWorkspaceMembership");
    }
});
