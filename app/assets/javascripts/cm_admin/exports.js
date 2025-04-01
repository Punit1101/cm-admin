$(document).on('click', '.export-to-file-btn', function(e) {
  e.preventDefault();
  var query_param = window.location.href.split("?")[1]
  var action = $('#export-to-file-form').get(0).getAttribute('action')
  $('#export-to-file-form').get(0).setAttribute('action', action + '?' + query_param);
  $("#export-to-file-form").submit();
});

$(document).on(
  "click",
  '[data-behaviour="export-select-all"]',
  function (e) {
    if($(this).is(':checked')){
      $('[data-behaviour="export-checkbox"]').prop('checked', true)
      
    } else {
      $('[data-behaviour="export-checkbox"]').prop('checked', false)
    }
  }
);

$(document).on(
  "click",
  '[data-behaviour="export-checkbox"]',
  function (e) {
    const container = $(this).closest('.row');
    if (container.find('[data-behaviour="export-checkbox"]:checked').length == container.find('[data-behaviour="export-checkbox"]').length) {
      $('[data-behaviour="export-select-all"]').prop('checked', true);
    } else {
      $('[data-behaviour="export-select-all"]').prop('checked', false);
    }
  }
);