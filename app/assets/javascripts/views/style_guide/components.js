chorus.views.Components = chorus.views.Base.extend({
    constructorName: "ComponentsView",
    templateName:"style_guide_components",

    typographies: [
        "<h1>h1.heading level one</h1>",
        "<h2>h2.heading level two</h2>",
        "<h3>h3.heading level three</h3>",
        "<h4>h4.heading level four</h4>",
        "<h5>h5.heading level five</h5>",
        "<h6>h6.heading level six</h6>",
        "<h5 class='h2'>h5 with h2 class</h5>",
        "<p>Standard paragraphy text. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.</p>",
        '<p class="deemphasized">deemphasized text</p>',
        '<p class="low_light">Low light text</p>',
        '<strong>Strong text!!!</strong>'
    ],

    links: [
        "<a href='#'>default link</a>",
        "<a class='link_low_light' href='#'>lowlight link</a>"
    ],


    baseListHtml: function() {
        return $('<ul><li>First Item</li><li>Second Item</li><li>Third Item</li></ul>');
    },

    lists: function() {
        return [
            { title: "Simple List", html: this.baseListHtml().outerHtml() },
            { title: "Horizontal List", html: this.baseListHtml().addClass("list_horizontal").outerHtml() },
            { title: "Horizontal Divided List", html: this.baseListHtml().addClass("list_horizontal_divided").outerHtml() },
            { title: "Breadcrumb List", html: this.baseListHtml().addClass("list_breadcrumb").outerHtml() },
            { title: "Vertical Divided List", html: this.baseListHtml().addClass("list_vertical_divided").outerHtml() },
            { title: "Selectable List", html: this.baseListHtml().addClass("list_selectable").find("li:eq(1)").text("Selected Item").addClass("selected").closest("ul").outerHtml() }
        ];
    },

    postRender: function() {
        Prism.highlightAll();
    },

    additionalContext: function() {
        return {
            typographies: this.typographies,
            links: this.links,
            lists: this.lists()
        };
    }
});