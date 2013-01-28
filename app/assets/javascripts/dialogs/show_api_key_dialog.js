chorus.dialogs.ShowApiKey = chorus.dialogs.Base.extend({
    templateName: "show_api_key",
    title: t("users.show_api_key_dialog.title"),
    events: {
    },
    persistent: true,

    additionalContext: function() {
        return {
            apiKey: chorus.session.user().get("apiKey")
        };
    }
});
