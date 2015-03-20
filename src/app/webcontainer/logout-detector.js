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


oxide.addMessageHandler("EVALUATE-CODE", function(msg) {
  var code = msg.args.code;
  code = "(function() {" + code + "})()";

  try {
    msg.reply({result: eval(code)});
  } catch(e) {
    msg.error("Code threw exception: \"" + e + "\"");
  }
});
