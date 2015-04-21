chorus.dialogs.VisualizationNotesNew = chorus.dialogs.MemoNew.extend({
    constructorName: "VisualizationNotesNew",

    title:t("notes.new_dialog.title"),
    submitButton: t("notes.button.create"),

    makeModel:function () {
        this.model = new chorus.models.Note({
            entityId:this.options.entityId,
            entityType:this.options.entityType,
            workspaceId: this.options.workspaceId
        });
        var subject = this.model.get("entityType");

        this.placeholder = t("notes.placeholder", {noteSubject: subject});
        this._super("makeModel", arguments);
    },

    postRender: function() {
        this._super("postRender", arguments);

        //this.showOptions();
        this.showVisualizationData();
    },

    showVisualizationData: function() {
        var $attachmentRow = $(Handlebars.helpers.renderTemplate("notes_new_file_attachment").toString());
        this.$(".attached_files").append($attachmentRow);

        var visualization = this.options.attachVisualization;

        var iconSrc = "images/workfiles/icon/img.png";
        $attachmentRow.find('img.icon').attr('src', iconSrc);
        $attachmentRow.find('span.name').text(visualization.fileName).attr('title', visualization.fileName);
        $attachmentRow.data("visualization", visualization);

        //$attachmentRow.find(".removeWidget").addClass("hidden");
        $attachmentRow.find(".removeWidget").remove();

        $attachmentRow.removeClass("hidden");
        $attachmentRow.addClass("visualization file_details");
    },

    modelSaved: function() {
        var note = this.model;
        var svgFile = new chorus.models.Base(this.options.attachVisualization);
        svgFile.url = function() {
             // weirdly, the note knows how to generate urls for its attachments;
            return note.url({isFile: true});
        };
        svgFile.bind("saved", this.svgSaved, this);
        svgFile.save();

        this._super("modelSaved");
    },

    svgSaved: function() {
        chorus.toast("dataset.visualization.note_from_chart.toast", {datasetName: this.options.entityName, toastOpts: {type: "success"}});
    }
});
