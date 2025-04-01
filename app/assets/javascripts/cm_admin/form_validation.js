$(document).on("click", '[data-behaviour="form_submit"]', function (e) {
  e.preventDefault();
  var submit = [];
  var form_class = $(this).data("form-class");
  $(
    "." + form_class + " input.required, ." + form_class + " textarea.required",
  ).each(function () {
    $(this).removeClass("is-invalid");
    let isValueNull = $(this).val().trim().length === 0
    if(isValueNull && $(this).attr('type') === 'file') {
      isValueNull = $(`[data-attachment-name="${$(this).attr('id')}_attachments"]`).not('.hidden').length === 0
    }
    if (isValueNull) {
      $(this).addClass("is-invalid");
      $(this)[0].scrollIntoView(true);
      submit.push(true);
    }
  });

  $("." + form_class + " select.required").each(function () {
    $(this).removeClass("is-invalid");
    let selected_value = $(this).val();
    if (!Array.isArray(selected_value)) {
      selected_value = selected_value.trim();
    }
    if (selected_value.length === 0) {
      $(this).parent().find("select").addClass("is-invalid");
      $(this)[0].scrollIntoView(true);
      submit.push(true);
    }
  });
  $(".nested_input_validation").each(function () {
    var class_name;
    class_name = $(this).data("class-name");
    $(this)
      .parents(":nth(1)")
      .find("." + class_name)
      .addClass("hidden");
    if ($(this).val().trim().length === 0) {
      $(this)
        .parents(":nth(1)")
        .find("." + class_name)
        .removeClass("hidden");
      $(this)[0].scrollIntoView(true);
      submit.push(true);
    }
  });
  if (submit.length === 0) {
    $("." + form_class).submit();
    return $('[data-behaviour="form_submit"]').button("loading");
  }
});

$(document).on("click", '[data-behaviour="discard_form"]', function (e) {
  e.preventDefault();
  const form = $(this).closest("form");
  form[0].reset();
  window.history.back();
});