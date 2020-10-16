Elm = require('./elm.js').Elm;
fs = require('fs');


if (process.argv.length !== 3) {
    console.log('Please use only one argument')
} else {
    file = process.argv[2]

    fs.readFile(file, 'utf-8', (err, data) => {
        if (err) {
            return console.log(err)
        }
        console.log('got data - ', data);
        const app = Elm.Main.init({
            flags: data
        });

        app.ports.sendLink.subscribe(function (url) {
            console.log(url)
        });
    })

}

