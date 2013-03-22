chorus.pages.UserIndexPage = chorus.pages.Base.extend({
    constructorName: 'UserIndexPage',

    crumbs:[
        { label:t("breadcrumbs.home"), url:"#/" },
        { label:t("breadcrumbs.users") }
    ],
    helpId: "users",

    setup:function () {
        this.collection = new chorus.collections.UserSet();
        this.collection.sortAsc("firstName");
        this.collection.fetch();

        var buttons = [];
        if (chorus.session.user().get("admin")) {
            buttons.push({
                    url:"#/users/new",
                    text:t("actions.add_user")
                }
            );
        }

        this.mainContent = new chorus.views.MainContentList({
            modelClass:"User",
            collection:this.collection,
            linkMenus:{
                sort:{
                    title:t("users.header.menu.sort.title"),
                    options:[
                        {data:"firstName", text:t("users.header.menu.sort.first_name")},
                        {data:"lastName", text:t("users.header.menu.sort.last_name")}
                    ],
                    event:"sort",
                    chosen: "firstName"
                }

            }
        });

        this.mainContent.contentHeader.bind("choice:sort", function (choice) {
            this.collection.sortAsc(choice);
            this.collection.fetch();
        }, this);

        this.mainContent.contentDetails = new chorus.views.ListContentDetails({ collection: this.collection, modelClass: "User", multiSelect: true, buttons: buttons});

        this.sidebar = new chorus.views.UserSidebar({listMode: true});

        this.multiSelectSidebarMenu = new chorus.views.MultipleSelectionSidebarMenu({
            selectEvent: "user:checked",
            actions: [
                '<a class="edit_tags">{{t "sidebar.edit_tags"}}</a>'
            ],
            actionEvents: {
                'click .edit_tags': _.bind(function() {
                    new chorus.dialogs.EditTags({collection: this.multiSelectSidebarMenu.selectedModels}).launchModal();
                }, this)
            }
        });

        this.subscribePageEvent("user:selected", this.setModel);
    },

    setModel:function(user) {
        this.model = user;
    }
});
