/**Workaround for https://github.com/ubports/morph-browser/issues/239 ( OTA-12 ) Until it is fixed in low level.
take a list of select options, pass it to a window.prompt so that it can be handled in QML with onJavascriptDialogRequested
**/
(function() {

    var generatedId = 0;

    function handleSelect(select) {

        var opts = []
        for (var i = 0; i < select.options.length; i++) {
            opts.push(select.options[i].innerText);
        }
        //Send a prompt so that WebEngine can intercept it with onJavascriptDialogRequested event
        var index = window.prompt("XXMORPHXX", JSON.stringify(opts));
        if (index !== null)  {
            select.options[index].selected = true;
            //fire the onchange event
            select.dispatchEvent(new Event('change', {bubbles: true}));
        }
    }

    //listen to mousedown events and see if it comes from a SELECT tag
    window.addEventListener('mousedown', function(evt) {
        if (evt.target.tagName === 'SELECT') {
            //disable default opening of select drop box
            evt.preventDefault();
            handleSelect(evt.target);
        }

    });

})();
