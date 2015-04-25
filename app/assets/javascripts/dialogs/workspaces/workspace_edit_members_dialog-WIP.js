chorus.dialogs.WorkspaceEditMembers = chorus.dialogs.Base.extend({
    constructorName: "WorkspaceEditMembers",
    templateName: "workspace_edit_members",
    title: t("workspace.edit_members_dialog.title"),
    additionalClass: "dialog_wide",
    persistent:true,

    events:{
        "click button.submit": "updateMembers"
    },

    makeModel:function () {
        this._super("makeModel", arguments);
        this.collection = new chorus.collections.UserSet();
        this.members = this.options.pageModel.members();

        this.collection.fetchAllIfNotLoaded();
        this.members.fetchAllIfNotLoaded();

        this.listenTo(this.collection, "reset", this.render);
        this.listenTo(this.members, "saved", this.saved);
    },

    subviews:{
        ".shuttle": "shuttle"
    },

    setup:function () {
        this.shuttle = new chorus.views.ShuttleWidget({
            collection: this.collection,
            selectionSource: this.members,
            nonRemovable: [this.options.pageModel.owner()],
            nonRemovableText: t("workspace.owner"),
            objectName: t("workspace.members")
        });
    },

    updateMembers:function () {
        this.$("button.submit").startLoading("actions.saving");

        var self = this;
        var ids = this.shuttle.getSelectedIDs();
        var users = _.map(ids, function (userId) {
            return self.collection.get(userId);
        });
        
        // before changing the membership, calculate what changed
        // how many added & how many removed
//         var howManyAdded = 0, howManyRemoved = 0;
        
//         var originalMembers = this.options.pageModel.members();
//         var newMembers = ids;
        
//         console.log ("EM: originalMembers:" + originalMembers);  // object of users
//         console.log ("EM: newMembers:" + typeof(newMembers) + ": " + newMembers);  // simple array of id#
        //console.log ("EM: users:" + users);   // object of users

        //var intheList = _.contains (originalMembers, users[1]);
        //console.log ("EM: in list? " + intheList);   // was it there?

//         var originalCrew = originalMembers.map(function (u) {
//             return u.get("id");
//         });
//         console.log ("EM: originalCrew: " + typeof(originalCrew) + ": " + originalCrew);

        // iterate through list of newMembers
        // if id is in originalMembers and not in newMembers, then increment numberOfRemoved
        // if id is in newMembers and not in originalMembers, then increment numberOfNew
        
//         _.each(originalCrew, function (i) {    
//             console.log ("--");
//             console.log ("?" + i);

//             var x = _.has(originalCrew, i);
//             console.log ("?x1:" + x);

            //_.has(originalCrew, i) ? howManyAdded++ : howManyRemoved++;
//         });
 
//          _.each(newMembers, function (i) {
//             console.log ("?" + i);

//             var y = _.has(originalCrew, i);
//             console.log ("?y1:" + y);

            //_.has(originalCrew, i) ? howManyAdded++ : howManyRemoved++;
//         });
               
//         console.log ("EM: added: " + howManyAdded);
//         console.log ("EM: removed: " + howManyRemoved);
        
//         console.log ("EM: original: " + originalMembers.length);
//         console.log ("EM: new:      " + ids.length);
//         console.log ("EM: changes:  " + (originalMembers.length - ids.length));
        
        self.members.reset(users);
        self.members.save();
    },

    calculateMembershipChanges: function () {
        // figure out how many are added and how many are removed
        
        // save originals
        // originalMembers = this.members

        // get new selected list
        // newMembers = this.shuttle.getSelectedIDs();

        // iterate through list of newMembers
        // if id is in originalMembers and not in newMembers, then increment numberOfRemoved
        // if id is in newMembers and not in originalMembers, then increment numberOfNew

    },

    saved:function () {
        this.pageModel.trigger("invalidated");
        this.closeModal();
    }
});


// potentials

// no changes 
// --

// single added, none removed
// 1 member added to the workspace (none removed)

// none added, single removed
// 1 member removed from the workspace (none added)

// single added, single removed
// 1 member added and 1 removed

// multiple added, none removed
// 2 members added (none removed)

// none added, multiple removed
// 2 members removed (none added)

// multiple added, multiple removed
// 2 members added and 5 removed

