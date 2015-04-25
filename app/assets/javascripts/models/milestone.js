chorus.models.Milestone = chorus.models.Base.extend({
    entityType: "Milestone",
    constructorName: "Milestone",
    urlTemplate: "workspaces/{{workspace.id}}/milestones/{{id}}",

    workspace: function() {
        if (!this._workspace && this.get("workspace")) {
            this._workspace = new chorus.models.Workspace(this.get("workspace"));
        }
        return this._workspace;
    },

    toggleState: function () {
        this.listenTo(this, "saved", this.savedToggle);

        if (this.get('state') === 'planned') {
            this.save( {state: 'achieved'}, {wait: true} );
        } else {
            this.save( {state: 'planned'}, {wait: true} );
        }
    },

    savedToggle: function() {
        var toggleMessage, type;
        if (this.get('state') === 'planned') {
            toggleMessage = "milestone.status.restarted.toast";
            type = "info";
        } else {
            toggleMessage = "milestone.status.completed.toast";
            type = "success";
        } 
        chorus.toast(toggleMessage, {milestoneName: this.name(), toastOpts: {type: type} });
        this.onClose();
    },
    
    onClose: function() {
        this.stopListening();
    }

});