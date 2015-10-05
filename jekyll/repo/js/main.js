// If an area is selected in the sidebar, adjust the sidebar's
// scroll offset so that the selected area appears right in the middle.
var selectedElement = document.querySelector('.area-list .selected');
if (selectedElement) {
  var parentElement = selectedElement.parentNode;
  parentElement.scrollTop = selectedElement.offsetTop - (parentElement.clientHeight / 2) + (selectedElement.clientHeight / 2);
}