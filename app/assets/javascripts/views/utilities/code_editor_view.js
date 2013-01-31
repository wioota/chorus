chorus.views.CodeEditorView = chorus.views.Base.extend({
    templateName: "code_editor_view",
    constructorName: 'CodeEditorView',

    setup: function(options) {
        this.options = _.extend({
            lineNumbers: true,
            fixedGutter: true,
            theme: "default",
            lineWrapping: true,
            onBlur: _.bind(this.onBlur, this),
            onChange: _.bind(this.onChange, this)
        }, options);
        this.subscriptions.push(chorus.PageEvents.subscribe("file:insertText", this.insertText, this));
    },

    teardown: function () {
        if (this.editor) {
            if (this.$('.CodeMirror').data('droppable')) {
                this.$('.CodeMirror').droppable("destroy");
            }
            this.$('.CodeMirror').off();
            this.$('.CodeMirror *').off();
            if (this.editor.getWrapperElement) {
                delete this.editor.getWrapperElement().CodeMirror;
            }
            this.editor.toTextArea();
        }
        this.$('textarea').unbind();

        delete this.options.onBlur;
        delete this.options.onChange;
        delete this.editor;
        delete this.textArea;

        this._super('teardown', [true]);
    },

    postRender: function() {
        _.defer(_.bind(function() {
            if(!this.torndown) {
                var textArea = this.$(".text_editor")[0];
                if (textArea !== this.textArea) {
                    this.textArea = textArea;
                    var editor = this.editor = CodeMirror.fromTextArea(this.textArea, this.options);
                    _.defer(function() { editor.refresh(); });
                    if (this.options.beforeEdit) { this.options.beforeEdit.call(this); }
                }

                this.$(".CodeMirror").droppable().on('drop', _.bind(this.acceptDrop, this));
            }
        }, this));
    },

    onBlur: function () {
      this.trigger('blur');
    },

    onChange: function () {
      this.trigger('change');
    },

    additionalContext: function() {
        return { editorContent: this.model.content() };
    },

    acceptDrop: function(e, ui) {
        var pos = this.editor.coordsChar({x: e.pageX, y: e.pageY});
        this.editor.setCursor(pos);
        this.insertText(ui.draggable.data("fullname"));
    },

    insertText: function(text) {
        this.editor.focus();
        this.editor.replaceSelection(text);
        this.editor.setCursor(this.editor.getCursor(false));
    }
});

// delegate methods to the CodeMirror editor
_.each([
    'getValue', 'setValue', 'getOption', 'setOption', 'getSelection',
    'setSelection', 'focus', 'getCursor', 'setCursor', 'lineCount', 'getLine'
], function(method) {
    chorus.views.CodeEditorView.prototype[method] = function() {
        return this.editor && this.editor[method].apply(this.editor, arguments);
    };
});
