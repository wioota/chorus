chorus.views.HelpLink = chorus.views.Base.extend({
    constructorName: 'HelpLinkView',
    templateName: 'help_link',

    linkAddress: function () {
        return 'help.link_address.' + chorus.models.Config.instance().get('branding');
    },

    additionalContext: function () {
        return {
            linkAddress: this.linkAddress
        };
    }
});
