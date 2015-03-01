chorus.dialogs.ChangePassword = chorus.dialogs.Base.extend({
    templateName: "change_password",
    title: function() {
        return this.changeSelfPassword() ? t("user.change_password_self.title") : t("user.change_password.title");
    },
    
    events: {
        "submit form":"save"
    },
    persistent:true,
    
    changeSelfPassword: function () {
        var sessionUserID = chorus.session.user().get("id");
        var passwordUserID = this.model.get("id");
        //this.model.isChangingSelf = (sessionUserID == passwordUserID) ? true : false;
        return (sessionUserID === passwordUserID) ? true : false;
    },

    save:function (e) {
        e && e.preventDefault();

        this.listenTo(this.model, "saved", this.saved);
        this.model.save({
            password: this.$("input[name=password]").val(),
            passwordConfirmation: this.$("input[name=passwordConfirmation]").val()
        });
    },

    saved:function () {
        var toastMessage, fullName;
        if (this.changeSelfPassword()) {
            toastMessage = "user.change_password_self.success.toast";
        }
        else {
            toastMessage = "user.change_password.success.toast";
            fullName =  this.model.displayName();
        }

        chorus.toast(toastMessage, {fullName: this.model.displayName(), toastOpts: {type: "success"}});
        this.closeModal();
    }
});
