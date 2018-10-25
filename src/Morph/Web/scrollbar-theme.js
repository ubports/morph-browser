(function() {
var css = "::-webkit-scrollbar {width: 5px;}::-webkit-scrollbar-track {border-radius: 0px;}::-webkit-scrollbar-thumb {background: rgba(0, 0, 0, 0.4);border-radius: 10px;}::-webkit-scrollbar-thumb:hover {background: rgba(0, 0, 0, 0.6);}";

if (typeof GM_addStyle != "undefined") {
	GM_addStyle(css);
} else if (typeof PRO_addStyle != "undefined") {
	PRO_addStyle(css);
} else if (typeof addStyle != "undefined") {
	addStyle(css);
} else {
	var node = document.createElement("style");
	node.type = "text/css";
	node.appendChild(document.createTextNode(css));
	var heads = document.getElementsByTagName("head");
	if (heads.length > 0) {
		heads[0].appendChild(node); 
	} else {
		// no head yet, stick it whereever
		document.documentElement.appendChild(node);
	}
}
})();
