Handlebars.registerPartial("errorDiv", '<div class="errors {{#unless serverErrors}}hidden{{/unless}}">{{#if serverErrors}}{{renderErrors serverErrors}}<a class="close_errors action" href="#">{{t "actions.close"}}</a>{{/if}}</div>');
Handlebars.registerPartial("itemTags", window.JST["templates/item_tags"]);
Handlebars.registerPartial("workspaceItemDetails", window.JST["templates/workspace_item_details"]);
Handlebars.registerPartial("itemLastComment", window.JST["templates/item_last_comment"]);
Handlebars.registerPartial("multipleSelectionHeader", window.JST["templates/multiple_selection_header"]);
Handlebars.registerPartial("listItemText", window.JST["templates/list_item_text"]);