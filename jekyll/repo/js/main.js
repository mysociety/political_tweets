// If an area is selected in the sidebar, adjust the sidebar's
// scroll offset so that the selected area appears right in the middle.
var selectedElement = document.querySelector('.area-list .selected');
if (selectedElement) {
  var parentElement = selectedElement.parentNode;
  parentElement.scrollTop = selectedElement.offsetTop - (parentElement.clientHeight / 2) + (selectedElement.clientHeight / 2);
}

// Detect whether this device hides its scrollbars. If it does,
// we can use `overflow: scroll` (rather than auto) and enable
// momentum scrolling for the area list on iOS devices.
var areaListElement = document.querySelector('.area-list');
var areaListStyle = window.getComputedStyle(areaListElement);
var areaListWidth = areaListElement.clientWidth + parseInt(areaListStyle['border-right-width']) + parseInt(areaListStyle['border-left-width']);
if (areaListWidth == areaListElement.offsetWidth) {
  document.body.className += ' device-has-invisible-scrollbars';
}
