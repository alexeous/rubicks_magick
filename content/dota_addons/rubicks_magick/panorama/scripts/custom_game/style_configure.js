var customUIRoot = $.GetContextPanel().GetParent().GetParent()
customUIRoot.style.zIndex = -1000 		// make our event catcher under any other Dota HUDs

var minimapContainer = customUIRoot.GetParent().FindChild("HUDElements").FindChild("minimap_container")
var glyphScan = minimapContainer.FindChild("GlyphScanContainer")
glyphScan.style.visibility = "collapse"	// hide glyph and scan buttons