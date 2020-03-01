/*Workaround for https://github.com/ubports/morph-browser/issues/239 ( OTA-12 ) Until it is fixed in low level.
take a list of select options, pass it to a window.prompt so that it can be handled in QML with onJavascriptDialogRequested*/

(function() {

    function handleSelect(select) {

        var opts = []
        for (var i = 0; i < select.options.length; i++) {
            opts.push(select.options[i].innerText.trim());
        }
        //Send a prompt so that WebEngine can intercept it with onJavascriptDialogRequested event
        var index = window.prompt("XX-MORPH-SELECT-OVERRIDE-XX",JSON.stringify({selectedIndex: select.selectedIndex, options: opts}));
        if (index !== null)  {
            select.options[index].selected = true;
            //fire the onchange event
            select.dispatchEvent(new Event('change', {bubbles: true}));
        }
    }
    //listen to mousedown events and see if it comes from a SELECT tag
    document.addEventListener('mousedown', function(evt) {
        var select = null
        if (evt.target.tagName === 'SELECT') {
            select = evt.target
        }else if (evt.composedPath()[0].tagName === 'SELECT') { // in case of event retargeting, original event is stored in composedPath array
            select = evt.composedPath()[0]
        }

        if (select!==null){
            //disable default opening of select drop box
            evt.preventDefault();
            handleSelect(select)
        }

    });

})();
