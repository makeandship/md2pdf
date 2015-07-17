var fs = require('fs'),
    tmp = require('tmp'),
    childProcess = require("child_process"),
    url = require('url'),
    path = require('path'),
    xregex = require('xregexp').XRegExp,
    cla = require("command-line-args"),
    nunjucks = require('nunjucks'),
    ncp = require('ncp').ncp,
    async = require('async');

var md = require('markdown-it')({
    html: true,
    linkify: false,
    breaks: true,
    typographer: true
}).use(require('markdown-it-classy'));

nunjucks.configure('template');

var cli = cla([{
    name: "verbose",
    type: Boolean,
    alias: "v",
    description: "Write plenty output"
}, {
    name: "help",
    type: Boolean,
    description: "Print usage instructions"
}, {
    name: "files",
    type: Array,
    defaultOption: true,
    description: "The input files"
}]);

/* parse the supplied command-line values */
var options = cli.parse();

/* generate a usage guide */
var usage = cli.getUsage({
    header: "Markdown to PDF generator",
    footer: "\n  Example: node index.js pinion_20150414.md. \n\n  For more information visit https://github.com/makeandship/makeandship-md-to-pdf"
});

if (options && options.files && options.files.length ) {

    async.eachSeries(options.files, function(item, callback) {
        var outputFile = item.replace('.md', '.pdf');
        convert(item, outputFile, function(err) {
            callback(err);
        });
    }, 
    function() {
        process.exit();
    });
} 
else {
    console.log(usage)
}

function convert(source, destination, callback) {
    fs.readFile(source, 'utf8', function(err, data) {
        if (err) {
            return console.log(err);
        }

        if (options.verbose) {
            console.log(data);
        }

        // replace ----- with html comment which will survive conversion
        data = data.toString().replace(/^-----$/mg, '<!-- break -->');

        // convert to html
        var html = md.render(data);

        // replace the comment with div to be styled by css
        html = html.replace(/<!-- break -->/g, '<div class="page-break"></div>');

        // wrap heading table groups in a div which is styled to avoid page breaks while maintaining group
        html = html.replace(/(<h[1-6]>.*?<\/h[1-6]>)[\r\n|\n|\r]*(<table>[.|\s|\S]*?<\/table>)/gm, function(all, title, table) {
            return '<div class="table-header-group">\n' + title + '\n' + table + '\n</div>';
        });

        rendered = nunjucks.render('index.html', {
            html: html
        });

        if (options.verbose) {
            console.log(rendered);
        }

        // create temporary directory for rendering the template
        var temporaryDirectory = tmp.dirSync();
        console.log("temporaryDirectory: ", temporaryDirectory.name);

        // copy everything except the original template
        ncp('template', temporaryDirectory.name, function(filename) {
            return 'index.html' !== filename
        },
        function(err) {
            if (err) {
                return console.error(err);
            }

            var tmpHtmlPath = path.join(temporaryDirectory.name, source + '.html');
            if (options.verbose) {
                console.log(tmpHtmlPath);
            }
            fs.writeFile(tmpHtmlPath, rendered);

            var childArgs = [
                '-i', tmpHtmlPath, 
                '-o', destination,
                '-d', '210 297',
                '-l', '20',
                '-t', '20',
                '-r', '20',
                '-b', '20'
            ];
            if (options.verbose) {
                console.log(childArgs);
            }

            childProcess.execFile('./html2pdf', childArgs, function(error, stdout, stderr) {
                if (err) {
                    callback(err);
                }
                if (stdout) console.log(stdout);
                if (stderr) console.error(stderr);

                callback();
            });
        });
    });
}