chorus.views.KaggleUserSidebar = chorus.views.Sidebar.extend({
    templateName:"kaggle/user_sidebar",

    events: {
        "click .actions .sendMessage": "launchSingleUserKaggleSendMessageDialog"
    },

    subviews: {
        '.tab_control': 'tabs'
    },

    setup: function(options) {
        this.workspace = options.workspace;
        this.subscribePageEvent("kaggle_user:selected", this.setKaggleUser);
        this.subscribePageEvent("kaggle_user:deselected", this.setKaggleUser);
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

    launchSingleUserKaggleSendMessageDialog: function(e) {
        e.preventDefault();
        new chorus.dialogs.ComposeKaggleMessage(
            { recipients: new chorus.collections.KaggleUserSet([this.resource]),
              workspace: this.workspace
            }).launchModal();
    }
});