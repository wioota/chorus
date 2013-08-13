var jsApiReporter;
(function() {
    var jasmineEnv = jasmine.getEnv();

    if (window.location.search.indexOf('phantom=') === -1) {
        jsApiReporter = new jasmine.JsApiReporter();
        var htmlReporter = new jasmine.HtmlReporter();

        jasmineEnv.addReporter(jsApiReporter);
        jasmineEnv.addReporter(htmlReporter);

        jasmineEnv.specFilter = function(spec) {
            return htmlReporter.specFilter(spec);
        };
    } else {
        var trivialReporter = new jasmine.TrivialReporter();

        jasmineEnv.specFilter = function(spec) {
            return trivialReporter.specFilter(spec);
        };
    }

    var currentWindowOnload = window.onload;

    window.onload = function() {
        if (currentWindowOnload) {
            currentWindowOnload();
        }
        execJasmine();
    };

    function execJasmine() {
        jasmineEnv.execute();
    }

})();
