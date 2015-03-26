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


oxide.addMessageHandler("evaluteSelectors", function(msg) {
    var selectors = msg.args.selectors;
    msg.reply({result: document.querySelector(selectors)});
});
