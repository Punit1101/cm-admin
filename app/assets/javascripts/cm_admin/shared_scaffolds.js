// This file is shared between rails 6 and 7 version

$(document).on(
  "keypress keyup blur",
  "[data-behaviour='decimal-only'], [data-behaviour='filter'][data-filter-type='range']",
  function (e) {
    var charCode = e.which ? e.which : e.keyCode;
    if (charCode > 31 && charCode != 46 && (charCode < 48 || charCode > 57))
      return false;
    return true;
  }
);

$(document).on(
  "keypress keyup blur",
  "[data-behaviour='integer-only']",
  function (event) {
    $(this).val(
      $(this)
        .val()
        .replace(/[^\d].+/, "")
    );
    if (event.which < 48 || event.which > 57) {
      event.preventDefault();
    }
  }
);

$(document).on("click", ".row-action-cell", function (e) {
  e.stopPropagation();
  if ($(this).find(".table-export-popup").hasClass("hidden")) {
    return $(this).find(".table-export-popup").removeClass("hidden");
  } else {
    return $(this).find(".table-export-popup").addClass("hidden");
  }
});

$(document).on("mouseleave", ".row-action-cell", function () {
  $(this).find(".table-export-popup").addClass("hidden");
});

$(document).on("click", '[data-behaviour="offcanvas"]', function (e) {
  const drawerFetchUrl = $(this).attr("data-drawer-fetch-url");
  const drawerContainer = $("[data-behaviour='cm-drawer-container']");

  if (!drawerFetchUrl || !drawerContainer) return;

  $.ajax({
    url: drawerFetchUrl,
    method: "GET",
    success: function (response) {
      drawerContainer.html(response);
      const drawerForm = new bootstrap.Offcanvas(
        drawerContainer.children().first()
      );
      drawerForm.show();
      initializeComponents();
      handleDrawerFormSubmission(drawerForm);
    },
    error: function (error) {
      console.error("Error:", error);
    },
  });
});

$(document).on("click", '[data-bs-dismiss="offcanvas"]', function (e) {
  $(document).off("submit", "[data-is-drawer-form='true']");
});

function handleDrawerFormSubmission(drawerForm) {
  $(document).on("submit", "[data-is-drawer-form='true']", function (e) {
    e.preventDefault();
    let url = $(this).attr("action");
    if (url.charAt(url.length - 1) === "/") {
      url = url.slice(0, -1);
    }
    url = `${url}.json`;
    $.ajaxSetup({
      headers: {
        "X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
      },
    });
    const isMultipart = $(this).attr("enctype") === "multipart/form-data";
    const ajaxOptions = {
      url: url,
      method: $(this).attr("method"),
      data: null,
      success: function (response) {
        $('[data-behavior="flag-alert"]').addClass("hidden");
        drawerForm.hide();
        $(document).off("submit", "[data-is-drawer-form='true']");
        const fromFieldId = $('[data-behavior="cm-drawer"]').attr(
          "data-from-field-id"
        );
        const fromField = $(`#${fromFieldId}`);
        toastMessage(response?.message);
        const bsToast = $('[data-behaviour="drawer-toast"]')[0];
        if (bsToast) {
          const toast = new bootstrap.Toast(bsToast);
          toast.show();
        }
        fromField.append(
          `<option value="${response?.data?.id}">${response?.data?.name}</option>`
        );
        fromField.val(response?.data?.id).change();
      },
      error: function (error) {
        $('[data-behavior="flag-alert"]').removeClass("hidden");
        $('[data-behavior="error-list"]').html(error?.responseJSON?.message);
      },
    };
    if (isMultipart) {
      ajaxOptions["data"] = new FormData($(this)[0]);
      ajaxOptions["contentType"] = false;
      ajaxOptions["processData"] = false;
      $.ajax(ajaxOptions);
    } else {
      ajaxOptions["data"] = $(this).serialize();
      $.ajax(ajaxOptions);
    }
  });
}

function toastMessage(message) {
  const toastHtml = ` 
    <div class="cm-toast-container">
      <div class="toast" role="alert" aria-live="assertive" aria-atomic="true"  data-behaviour="drawer-toast">
        <div class="d-flex">
          <div class="toast-body">${message}</div>
          <button type="button" class="btn-close me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
      </div>
    </div>
  `;
  $('[data-behaviour="flash-container"]').html(toastHtml);
}

$(document).on("change", '[data-field-type="linked-field"]', function (e) {
  e.stopPropagation();
  var params = {};
  params[$(this).data("field-name")] = $(this).val();
  var request_url = $(this).data("target-url") + "?" + $.param(params);
  $.ajax(request_url, {
    type: "GET",
    success: function (data) {
      apply_response_to_field(data);
    },
    error: function (jqxhr, textStatus, errorThrown) {
      alert("Something went wrong. Please try again later.\n" + errorThrown);
    },
  });
});

function apply_response_to_field(response) {
  $.each(response["fields"], function (key, value) {
    switch (value["target_type"]) {
      case "select":
        update_options_in_select(value["target_value"]);
        break;
      case "input":
        update_options_input_value(value["target_value"]);
        break;
      case "toggle_visibility":
        toggle_field_visibility(value["target_value"]);
    }
  });
}

function update_options_input_value(field_obj) {
  var input_tag = $("#" + field_obj["table"] + "_" + field_obj["field_name"]);
  input_tag.val(field_obj["field_value"]);
}

function update_options_in_select(field_obj) {
  var select_tag = $("#" + field_obj["table"] + "_" + field_obj["field_name"]);
  select_tag.empty();
  $.each(field_obj["field_value"], function (key, value) {
    select_tag.append(
      $("<option></option>").attr("value", value[1]).text(value[0])
    );
  });
}

function toggle_field_visibility(field_obj) {
  var element = $("#" + field_obj["table"] + "_" + field_obj["field_name"]);
  element.closest(".form-field").toggleClass("hidden");
}

$(document).on("cocoon:after-insert", ".nested-field-wrapper", function (e) {
  e.stopPropagation();
  replaceAccordionTitle($(this));
});

$(document).on("cocoon:after-remove", ".nested-field-wrapper", function (e) {
  e.stopPropagation();
  replaceAccordionTitle($(this));
});

$(document).ready(function () {
  $(".nested-field-wrapper").each(function () {
    replaceAccordionTitle($(this));
  });
});

var replaceAccordionTitle = function (element) {
  var i = 0;
  var table_name = $(element).data("table-name");
  var model_name = $(element).data("model-name");
  $(element)
    .find("[data-card-name='" + table_name + "']")
    .each(function () {
      i++;
      var accordion_title = model_name + " " + i;
      var accordion_id = table_name + "-" + i;
      $(this).find(".card-title").text(accordion_title);
      $(this)
        .find(".card-title")
        .attr("data-bs-target", "#" + accordion_id);
      $(this).find(".accordion-collapse").attr("id", accordion_id);
    });
  initializeComponents();
};

export function initializeComponents() {
  $(".select-2").select2({
    theme: "bootstrap-5",
  });
  flatpickr("[data-behaviour='date-only']", {
    dateFormat: "d-m-Y",
  });
  flatpickr("[data-behaviour='date-time']", {
    enableTime: true,
  });
  flatpickr("[data-behaviour='filter'][data-filter-type='date']", {
    mode: "range",
  });
  var el = document.getElementsByClassName("columns-list");
  if (el[0]) {
    Sortable.create(el[0], {
      handle: ".dragger",
      animation: 150,
    });
  }

  var headerElemHeight = $(".page-top-bar").height() + 64;
  var calculatedHeight = "calc(100vh - " + headerElemHeight + "px" + ")";
  $(".table-wrapper").css("maxHeight", calculatedHeight);
}
