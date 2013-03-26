Handlebars.registerPartial("errorDiv", '<div class="errors {{#unless serverErrors}}hidden{{/unless}}">{{#if serverErrors}}{{renderErrors serverErrors}}<a class="close_errors action" href="#">{{t "actions.close"}}</a>{{/if}}</div>');
Handlebars.registerPartial("itemTags", window.JST["templates/item_tags"]);
Handlebars.registerPartial("multipleSelectionHeader", window.JST["templates/multiple_selection_header"]);
Handlebars.registerPartial("listItemText", window.JST["templates/list_item_text"]);