export const handleScroll = () => {
  var header = document.getElementById('page-sticky-header')
  var sticky = header.offsetTop
  if (window.pageYOffset > sticky) {
    header.classList.add('sticky-pageheader')
  } else {
    header.classList.remove('sticky-pageheader')
  }
}
