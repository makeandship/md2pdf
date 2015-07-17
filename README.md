# MarkDown to PDF

NodeJS script to convert MarkDown documents into PDF via HTML rendered using the finest Mac OS WebView. Unlike other converters, this outputs PDFs with selectable text and working hyperlinks.

### To set up

~~~
npm install
~~~

### To make PDFs

~~~
node index.js example.md file2.md file3.md ...
~~~

### To build the command line tool 

This places `html2pdf` in the root directory

~~~~
cd MSHTML2PDF/scripts
./build.sh
~~~~

### To use the html to pdf command line tool

~~~~
html2pdf -i input.html -o output.pdf -d 210 297 -l 20 -t 20 -r 20 -b 20
~~~~

Dimensions are millimeters

### Contact

[hello@makeandship.co.uk](mailto:hello@makeandship.co.uk)
