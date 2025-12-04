//= require jquery
//= require_tree .
$(document).ready(function(){
  $(document).on('click', '.js_select_package', function(){
    const select = document.querySelector("#invitation_type_id");
    select.value = $(this).attr("data-value");
  });

  new TomSelect("#countrySelect", {
    create: false,      // запрет добавлять новые значения
    sortField: "text",
    maxOptions: null,
    placeholder: "Start introducing citizenship..."
  });

  (function ($) {
    const year = new Date().getFullYear();

  // --- Datepickers ---------------------------------------
    const dateConfigs = [
      { selector: '#birthDate',       start: year - 100, end: year,       required: true  },
      { selector: '#arival_date',     start: year,       end: year + 10, required: true  },
      { selector: '#departure_date',  start: year,       end: year + 10, required: true  },
      { selector: '#passportExpire',  start: year,       end: year + 40, required: false }
    ];

    dateConfigs.forEach(cfg => {
      $(cfg.selector).datePicker({
        startYear: cfg.start,
        endYear:   cfg.end,
        required:  cfg.required
      });
    });

  // --- Accordion ------------------------------------------
    $(".title_block").on("click", function () {
      const item = $(this).closest(".accordion_item");
      const info = item.find(".info");

      if (item.hasClass("active_block")) {
        item.removeClass("active_block");
        info.slideUp();
      } else {
        item
        .addClass("active_block")
        .siblings(".active_block")
        .removeClass("active_block")
        .children(".info")
        .stop(true, true)
        .slideUp();

        info.stop(true, true).slideDown();
      }
    });

  })(jQuery);

  // ============= FORM REQUEST

  (function ($) {

  // ---------------------------------------------------------
  // UNIVERSAL FIELD VALIDATION
  // ---------------------------------------------------------
    function setValidation($field, message, rule) {
      const $group = $field.closest('.form-group');
      $group.find(".invalid-feedback").remove();

      const valid = rule($field);

      $field.toggleClass('is-valid', valid);
      $field.toggleClass('is-invalid', !valid);

      if (!valid && message)
        $group.append(`<div class="invalid-feedback">${message}</div>`);

      return valid;
    }

    const validateRequired = f => !!f.val().trim();
    const validateEmail = f => /^[a-zA-Z0-9_.+-]+@([\w-]+\.)+[a-zA-Z0-9]{2,}$/.test(f.val());

  // ---------------------------------------------------------
  // MAIN FORM VALIDATION
  // ---------------------------------------------------------
    function validateForm() {
      let valid = true;

      valid &= setValidation($("#invitation_type_id"), "Please select invitation type", f =>
        f.val() !== "0"
        );

      valid &= setValidation($("#email"), "Please provide a valid e-mail address", validateEmail);
      valid &= setValidation($("#arival_date"), "Please provide arrival date", validateRequired);
      valid &= setValidation($("#departure_date"), "Please provide departure date", validateRequired);

      $("#persons .person").each(function () {
        const $p = $(this);

        valid &= setValidation($p.find("[name=surname]"), "Surname required", validateRequired);
        valid &= setValidation($p.find("[name=sex]"), "Sex required", f => f.val() !== "-1");
        valid &= setValidation($p.find("[name=birthDate]"), "Birth date required", validateRequired);
        valid &= setValidation($p.find("[name=citizenship]"), "Citizenship required", validateRequired);
        valid &= setValidation($p.find("[name=passport]"), "Passport required", validateRequired);
      });

      return !!valid;
    }

  // ---------------------------------------------------------
  // DOCUMENT READY
  // ---------------------------------------------------------
    $(function () {

      $("#persons").on("click", ".removePerson", function () {
        $(this).closest(".person").remove();
      });

      $("#submitInvitation").on("click", function (e) {
        e.preventDefault();

        if (!validateForm()) return;

        $(this).prop("disabled", true).text("Please wait...");

        const result = {
          invitation_type_id: $("#invitation_type_id").val(),
          email: $("#email").val(),
          arrival_date: $("#arival_date").val(),
          departure_date: $("#departure_date").val(),
          visa_obtain_place: $("#visa_obtain_place").val(),
          cities: $("#cities").val(),
          hotels: $("#hotels").val(),
          comments: $("#comments").val(),
          persons: []
        };

        $("#persons .person").each(function () {
          const $p = $(this);
          result.persons.push({
            surname: $p.find("[name=surname]").val(),
            name: $p.find("[name=name]").val(),
            middle_name: $p.find("[name=middlename]").val(),
            sex: $p.find("[name=sex]").val(),
            citizenship: $p.find("[name=citizenship]").val(),
            passport: $p.find("[name=passport]").val(),
            passportExpire: $p.find("[name=passportExpire]").val(),
            date_of_birth: $p.find("[name=birthDate]").val()
          });
        });

        console.log(JSON.stringify(result));
      });

    });

  })(jQuery);
})

(function () {
  // высота фиксированной шапки (поставь свою)
  const OFFSET = 80;

  function smoothScrollTo(target) {
    const el = typeof target === "string" ? document.querySelector(target) : target;
    if (!el) return;

    const top = el.getBoundingClientRect().top + window.pageYOffset - OFFSET;

    window.scrollTo({
      top,
      behavior: "smooth"
    });
  }

  // клики по ссылкам/кнопкам
  document.addEventListener("click", (e) => {
    const link = e.target.closest('a[href^="#"], [data-scroll]');
    if (!link) return;

    const selector = link.dataset.scroll || link.getAttribute("href");
    if (!selector || selector === "#") return;

    const el = document.querySelector(selector);
    if (!el) return;

    e.preventDefault();
    smoothScrollTo(el);

    // обновим хэш в адресной строке без прыжка
    history.pushState(null, "", selector);
  });

  // если открыли страницу сразу с хэшем
  window.addEventListener("load", () => {
    if (location.hash) smoothScrollTo(location.hash);
  });
})();