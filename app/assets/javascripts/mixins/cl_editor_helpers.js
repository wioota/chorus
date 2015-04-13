chorus.Mixins.ClEditor = {
    // makeEditor: function($container, controlSelector, inputName, options) {
     makeEditor: function($container, inputName, options) {
        
        // which controls should be available in the textarea
        //var controls = ["bold", "italic", "bullets", "numbers", "link", "unlink"];
//        
        // instead of using the CLeditor built in toolbar, make a different toolbar of links
//         $container.find(controlSelector).empty();
//         _.each(controls, function(control, i) {
//             var $controlContainer = $container.find(controlSelector);
//             $controlContainer.append($('<a class="'+ control +'" href="#"></a>').text(t("workspace.settings.toolbar."+ control)));
//             if(i < controls.length - 1) {
//                 $controlContainer.append($('<span>|</span>'));
//             }
//             $container.find("a." + control).unbind("click").bind("click", _.bind(this["onClickToolbar"+ _.capitalize(control)], $container));
//         }, this);

        // END alt toolbar
        
        options = options || {};

        // which controls appear in the graphic toolbar
        var editorOptions = _.extend(options, {controls: "bold italic | bullets numbering | link unlink"});

        var editor = $container.find("textarea[name='"+ inputName +"']").cleditor(editorOptions)[0];
//         $(editor.doc).find("body").focus();
//         $(editor.doc).find(inputName).focus();
            $(editor).focus();
        // editor.focus();
        return editor;
    },

//     onClickToolbarBold: function(e) {
//         e && e.preventDefault();
//         this.find(".cleditorButton[title='Bold']").click();
//     },

//     onClickToolbarItalic: function(e) {
//         e && e.preventDefault();
//         this.find(".cleditorButton[title='Italic']").click();
//     },

//     onClickToolbarBullets: function(e) {
//         e && e.preventDefault();
//         this.find(".cleditorButton[title='Bullets']").click();
//     },

//     onClickToolbarNumbers: function(e) {
//         e && e.preventDefault();
//         this.find(".cleditorButton[title='Numbering']").click();
//     },

//     onClickToolbarLink: function(e) {
//         e && e.preventDefault();
//         this.find(".cleditorButton[title='Insert Hyperlink']").click();
//         e.stopImmediatePropagation();
//     },

//     onClickToolbarUnlink: function(e) {
//         e && e.preventDefault();
//         this.find(".cleditorButton[title='Remove Hyperlink']").click();
//     },

    getNormalizedText: function($textarea) {
        return $textarea.val()
            .replace(/(<div><br><\/div>)+$/, "")
            .replace(/^<br>$/, "");
    }
};
