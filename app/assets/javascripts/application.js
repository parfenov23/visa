//= require jquery
//= require date_picker
//= require invitation_form
$(document).ready(function(){
  $(document).on('click', '.js_select_package', function(){
    const select = document.querySelector("#invitation_type_id");
    select.value = $(this).attr("data-value");
    // Обновить итоговую цену у кнопки отправки (invitation_form.js).
    select.dispatchEvent(new Event("change", { bubbles: true }));
  });

  // TomSelect грузится с CDN и может не загрузиться (медленная сеть, блокировщик).
  // Без try/catch ошибка здесь отключала бы датапикеры и валидацию всей формы.
  // jQuery ready в deferred-скрипте срабатывает раньше, чем выполнится следующий
  // deferred-скрипт tom-select с CDN. Нативный DOMContentLoaded наступает только
  // после всех deferred-скриптов — пробуем ещё раз на нём (и на load как запасной).
  function initCountrySelect() {
    const el = document.querySelector("#countrySelect");
    if (!el || el.tomselect) return true;
    if (typeof TomSelect === "undefined") return false;
    try {
      new TomSelect(el, {
        create: false,      // запрет добавлять новые значения
        sortField: "text",
        maxOptions: null,
        placeholder: "Start introducing citizenship..."
      });
    } catch (e) {
      console.warn("TomSelect init failed, falling back to native select", e);
    }
    return true;
  }
  if (!initCountrySelect()) {
    document.addEventListener("DOMContentLoaded", initCountrySelect, { once: true });
    window.addEventListener("load", initCountrySelect, { once: true });
  }

  (function ($) {
    const year = new Date().getFullYear();

  // --- Datepickers ---------------------------------------
    const dateConfigs = [
      { selector: '#birthDate',       start: year - 100, end: year,       required: true  },
      { selector: '#arival_date',     start: year,       end: year + 10, required: true,  ascending: true },
      { selector: '#departure_date',  start: year,       end: year + 10, required: true,  ascending: true },
      { selector: '#passportExpire',  start: year,       end: year + 40, required: false, ascending: true }
    ];

    dateConfigs.forEach(cfg => {
      $(cfg.selector).datePicker({
        startYear: cfg.start,
        endYear:   cfg.end,
        required:  cfg.required,
        yearsAscending: !!cfg.ascending
      });
    });

  // --- Accordion ------------------------------------------
    $(".title_block").on("click", function () {
      const item = $(this).closest(".accordion_item");
      const info = item.find(".info");

      if (item.hasClass("active_block")) {
        item.removeClass("active_block");
        $(this).attr("aria-expanded", "false");
        info.slideUp();
      } else {
        item
        .siblings(".active_block")
        .find(".title_block")
        .attr("aria-expanded", "false");

        item
        .addClass("active_block")
        .siblings(".active_block")
        .removeClass("active_block")
        .children(".info")
        .stop(true, true)
        .slideUp();

        $(this).attr("aria-expanded", "true");
        info.stop(true, true).slideDown();
      }
    });

    // Заголовки FAQ — role="button": открываются с клавиатуры (Enter / Space).
    $(".title_block").on("keydown", function (e) {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        $(this).trigger("click");
      }
    });

  })(jQuery);

});

(function () {
  // высота фиксированной шапки (поставь свою)
  const OFFSET = 80;

  function smoothScrollTo(target) {
    const el = typeof target === "string" ? document.querySelector(target) : target;
    if (!el) return;

    const top = el.getBoundingClientRect().top + window.pageYOffset - OFFSET;

    const reduceMotion = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    window.scrollTo({
      top,
      behavior: reduceMotion ? "auto" : "smooth"
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