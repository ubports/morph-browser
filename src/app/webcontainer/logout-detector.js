oxide.sendMessage('domChanged', 'Some message');

var MutationObserver = window.MutationObserver || window.WebKitMutationObserver;

var observer = new MutationObserver(function(mutations) {
    var addnodes = []
    mutations.forEach(function(mutation) {
        for (var i in mutation.addedNodes) {
            addnodes.push(mutation.addedNodes[i].className)
        }
    });

    oxide.sendMessage('domChanged', JSON.stringify(addnodes))
});
observer.observe(document.body, {childList: true, subtree: true });


oxide.addMessageHandler("evaluateSelectors", function(msg) {
    var selectors = msg.args.selectors;
    console.log("Evaluating selectors: " + selectors);
    var match = document.querySelector(selectors);
    msg.reply({result: (match !== null)});
});
