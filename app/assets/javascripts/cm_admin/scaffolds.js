import jQuery from "jquery";
window.jQuery = jQuery; // <- "select2" will check this
window.$ = jQuery;

// This is a hack to fix 'process is not defined'
// Ref article: https://adambien.blog/roller/abien/entry/uncaught_referenceerror_process_is_not
// Based on this filter dropdown works.
window.process = {
  env: {
    NODE_ENV: "development",
  },
};

import "moment";
import "bootstrap";
import "@popperjs/core";
import "flatpickr";
import "trix";
import "@rails/actiontext";
import Select2 from "select2";
Select2();

// import '@nathanvda/cocoon'
import "daterangepicker";

document.addEventListener("turbo:load", function () {
  flatpickr("[data-behaviour='date-only']", {
    dateFormat: "d-m-Y",
  });
  flatpickr("[data-behaviour='date-time']", {
    enableTime: true,
  });
  flatpickr("[data-behaviour='filter'][data-filter-type='date']", {
    mode: "range",
  });
  $(".select-2").select2({
    theme: "bootstrap-5",
  });
  setup_select_2_ajax();
  const bsToast = $('[data-behaviour="toast"]')[0];
  if (bsToast) {
    const toast = new bootstrap.Toast(bsToast);
    toast.show();
  }
  var el = $("[data-section='nested-form-body']");
  if (el[0]) {
    Sortable.create(el[0], {
      handle: ".drag-handle",
      animation: 150,
      onUpdate: function (evt) {
        var itemEl = evt.item;
        $("[data-section='nested-form-body'] tr").each(function (index, el) {
          $(el)
            .find(".hidden-position")
            .val(index + 1);
        });
      },
    });
  }
});

$(document).on(
  "click",
  '[data-behaviour="toggle-profile-popup"]',
  function (e) {
    e.stopPropagation();
    $('[data-behaviour="profile-popup"]').toggleClass("hidden");
  }
);

$(document).on("click", function (e) {
  var popup = $('[data-behaviour="profile-popup"]');
  if (!popup.is(e.target) && popup.has(e.target).length === 0) {
    popup.addClass("hidden");
  }
});

$(document).on("click", ".destroy-attachment button", function (e) {
  e.preventDefault();
  var ar_id = $(this).parent(".destroy-attachment").data("ar-id");
  $(this).parent(".destroy-attachment").addClass("hidden");
  $(this).append(
    '<input type="text" name="attachment_destroy_ids[]" value="' + ar_id + '"/>'
  );
});

$(document).on(
  "click",
  '[data-behaviour="permission-check-box"]',
  function (e) {
    var form_check = $(this).closest(".form-check");
    var form_field = $(this).closest(".form-field");
    if ($(this).is(":checked")) {
      form_check.find(".cm-select-tag").removeClass("hidden");
    } else {
      form_check.find(".cm-select-tag").addClass("hidden");
    }
    if (
      form_field.find('[data-behaviour="permission-check-box"]:checked')
        .length ==
      form_field.find('[data-behaviour="permission-check-box"]').length
    ) {
      form_field
        .find('[data-behaviour="permission-check-all"]')
        .prop("checked", true);
    } else {
      form_field
        .find('[data-behaviour="permission-check-all"]')
        .prop("checked", false);
    }
  }
);

$(document).on(
  "click",
  '[data-behaviour="permission-check-all"]',
  function (e) {
    var form_field = $(this).closest(".form-field");
    if ($(this).is(":checked")) {
      form_field
        .find('[data-behaviour="permission-check-box"]')
        .prop("checked", true);
      form_field.find(".cm-select-tag").removeClass("hidden");
    } else {
      form_field
        .find('[data-behaviour="permission-check-box"]')
        .prop("checked", false);
      form_field.find(".cm-select-tag").addClass("hidden");
    }
  }
);

window.addEventListener("popstate", (e) => window.location.reload());

function setup_select_2_ajax() {
  $(".select-2-ajax").each(function (index, element) {
    $(element).select2({
      ajax: {
        url: $(element)[0]["dataset"].ajaxUrl,
        dataType: "json",
        processResults: (data, params) => {
          return {
            results: data.results,
          };
        },
      },
      minimumInputLength: 0,
    });
  });
}
