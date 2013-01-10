chorus.views.KaggleUserSidebar = chorus.views.Sidebar.extend({
    templateName:"kaggle/user_sidebar",

    events: {
        "click .multiple_selection .sendMessage": "launchMultipleUserKaggleSendMessageDialog",
        "click .actions .sendMessage": "launchSingleUserKaggleSendMessageDialog"
    },

    subviews: {
        '.tab_control': 'tabs',
        '.multiple_selection': 'multiSelect'
    },

    setup: function(options) {
        this.workspace = options.workspace;
        chorus.PageEvents.subscribe("kaggleUser:selected", this.setKaggleUser, this);
        chorus.PageEvents.subscribe("kaggleUser:deselected", this.setKaggleUser, this);
        this.multiSelect = new chorus.views.MultipleSelectionSidebarMenu({
            selectEvent: "kaggleUser:checked",
            actions: [
                '<a class="sendMessage" href="#">{{t "actions.send_kaggle_message"}}</a>'
            ]
        });
        this.registerSubView(this.multiSelect);
    },

    additionalContext: function() {
        return { hasModel: this.model !== null };
    },

    setKaggleUser: function(user) {
        this.resource = this.model = user;
        if (this.tabs) {
            this.tabs.teardown();
        }
        if(user) {
            this.tabs = new chorus.views.TabControl(["information"]);
            this.tabs.information = new chorus.views.KaggleUserInformation({
                model: user
            });
            this.registerSubView(this.tabs);
        } else {
            this.tabs = null;
        }
        this.render();
    },

    launchMultipleUserKaggleSendMessageDialog: function(e) {
        e.preventDefault();
        new chorus.dialogs.ComposeKaggleMessage({recipients: this.multiSelect.selectedModels, workspace: this.workspace}).launchModal();
    },

    launchSingleUserKaggleSendMessageDialog: function(e) {
        e.preventDefault();
        new chorus.dialogs.ComposeKaggleMessage(
            { recipients: new chorus.collections.KaggleUserSet([this.resource]),
              workspace: this.workspace
            }).launchModal();
    }
});