// Форма заявки на главной (#invitationForm): инлайн-валидация, итоговая цена,
// состояние отправки и защита от двойного клика.
// Ванильный JS; запускается после DOMContentLoaded, когда application.js уже
// поставил датапикеры и tom-select (их jQuery-ready колбэки срабатывают раньше).
(function () {
  "use strict";

  var MESSAGES = {
    package: "Please choose the type of invitation.",
    arival_date: "Please choose your date of arrival.",
    departure_date: "Please choose your date of departure.",
    surname: "Please enter your surname as in your passport.",
    sex: "Please choose your sex.",
    citizenship: "Please choose your citizenship.",
    birthDate: "Please choose your date of birth.",
    passport: "Please enter your passport number.",
    email: "Please enter your email — we will send the invitation there."
  };

  function parseDate(value) {
    var m = /^(\d{2})\.(\d{2})\.(\d{4})$/.exec(value || "");
    if (!m) return null;
    var d = new Date(+m[3], +m[2] - 1, +m[1]);
    return d.getMonth() === +m[2] - 1 ? d : null;
  }

  function today() {
    var t = new Date();
    return new Date(t.getFullYear(), t.getMonth(), t.getDate());
  }

  function init() {
    var form = document.getElementById("invitationForm");
    if (!form || form.dataset.invReady) return;
    form.dataset.invReady = "1";

    // Своя валидация с сообщениями у полей; без JS работает нативная (required).
    form.noValidate = true;

    var submitBtn = form.querySelector(".inv-submit__btn");
    var errorSummary = document.getElementById("invErrorSummary");
    var submitting = false;

    // ---- Подписи и группы для датапикеров (3 селекта вместо скрытого input) ----
    form.querySelectorAll("input[data-inv-date]").forEach(function (input) {
      var holder = input.nextElementSibling;
      var label = document.getElementById(input.id + "-label");
      if (!holder || !holder.classList.contains("date-picker-holder")) return;
      holder.setAttribute("role", "group");
      if (label) holder.setAttribute("aria-labelledby", label.id);
      var first = holder.querySelector("select");
      if (first && label) {
        first.id = input.id + "_day";
        label.setAttribute("for", first.id);
      }
    });

    // ---- Поиск поля и «фокусируемого» элемента для него ----
    function fieldWrap(el) { return el.closest(".inv-field"); }

    function focusTarget(el) {
      if (el.dataset.invDate !== undefined) {
        var holder = el.nextElementSibling;
        if (holder && holder.classList.contains("date-picker-holder")) {
          var empty = Array.prototype.find.call(holder.querySelectorAll("select"), function (s) { return !s.value; });
          return empty || holder.querySelector("select");
        }
      }
      if (el.tomselect) return el.tomselect.control_input;
      return el;
    }

    function ariaTargets(el) {
      var list = [el];
      if (el.dataset.invDate !== undefined && el.nextElementSibling) {
        list = Array.prototype.slice.call(el.nextElementSibling.querySelectorAll("select"));
      } else if (el.tomselect) {
        list = [el.tomselect.control_input];
      }
      return list;
    }

    function setError(el, message) {
      var wrap = fieldWrap(el);
      if (!wrap) return;
      var errId = (el.id || el.name) + "-error";
      var err = document.getElementById(errId);
      if (message) {
        if (!err) {
          err = document.createElement("span");
          err.className = "inv-error";
          err.id = errId;
          wrap.appendChild(err);
        }
        err.textContent = message;
        wrap.classList.add("inv-field--invalid");
      } else {
        if (err) err.remove();
        wrap.classList.remove("inv-field--invalid");
      }
      ariaTargets(el).forEach(function (t) {
        var ids = (t.getAttribute("aria-describedby") || "").split(/\s+/).filter(function (id) { return id && id !== errId; });
        if (message) { t.setAttribute("aria-invalid", "true"); ids.push(errId); }
        else { t.removeAttribute("aria-invalid"); }
        if (ids.length) t.setAttribute("aria-describedby", ids.join(" "));
        else t.removeAttribute("aria-describedby");
      });
    }

    function check(el) {
      var value = (el.value || "").trim();
      if (el.required && !value) return MESSAGES[el.name] || "This field is required.";

      if (el.type === "email" && value && !/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(value)) {
        return "Please enter a valid email, e.g. john_doe@example.com.";
      }

      var rule = el.dataset.invDate;
      if (rule !== undefined && value) {
        var date = parseDate(value);
        if (!date) return "Please choose day, month and year.";
        if (rule === "past" && date >= today()) return "Date of birth must be in the past.";
        if (rule === "future" && date < today()) return "Date of arrival can't be in the past.";
        if (rule.indexOf("after:") === 0) {
          var other = parseDate((document.getElementById(rule.slice(6)) || {}).value);
          if (other && date < other) return "Departure can't be earlier than arrival.";
        }
      }
      return "";
    }

    function fields() {
      return Array.prototype.filter.call(form.elements, function (el) {
        return el.name && el.closest(".inv-field") && (el.required || el.type === "email" || el.dataset.invDate !== undefined);
      });
    }

    function validateField(el) {
      var msg = check(el);
      setError(el, msg);
      return !msg;
    }

    // Проверяем поле после того, как пользователь с ним поработал, и снимаем
    // ошибку сразу, как только значение стало корректным.
    fields().forEach(function (el) {
      var wrap = fieldWrap(el);
      var touched = false;
      var run = function () {
        if (touched || wrap.classList.contains("inv-field--invalid")) validateField(el);
        // Связанная дата отъезда перепроверяется при смене даты приезда.
        if (el.id === "arival_date") {
          var dep = document.getElementById("departure_date");
          if (dep && dep.value) validateField(dep);
        }
      };
      // Датапикер пишет значение в скрытый input без события — слушаем его селекты.
      var sources = el.dataset.invDate !== undefined && el.nextElementSibling
        ? Array.prototype.slice.call(el.nextElementSibling.querySelectorAll("select"))
        : [el];
      sources.forEach(function (s) {
        s.addEventListener("change", function () {
          // Дату проверяем, только когда выбраны все три части (или уже была ошибка).
          if (el.dataset.invDate !== undefined) {
            var all = sources.every(function (x) { return x.value; });
            if (all) touched = true;
          } else {
            touched = true;
          }
          run();
        });
      });
      if (sources[0] === el) {
        el.addEventListener("blur", function () { if (el.value.trim()) touched = true; run(); });
        el.addEventListener("input", function () { if (wrap.classList.contains("inv-field--invalid")) validateField(el); });
      }
    });

    // ---- Итоговая цена выбранного тарифа ----
    var pkg = document.getElementById("invitation_type_id");
    var summary = document.getElementById("invSummary");
    function updateSummary() {
      if (!pkg || !summary) return;
      var opt = pkg.options[pkg.selectedIndex];
      if (!opt || !opt.value) { summary.hidden = true; return; }
      var price = opt.getAttribute("data-price") || "";
      var text = opt.textContent.trim();
      var label = price && text.slice(-price.length) === price ? text.slice(0, -price.length).trim() : text;
      document.getElementById("invSummaryLabel").textContent = label;
      document.getElementById("invSummaryPrice").textContent = price;
      summary.hidden = !price;
    }
    if (pkg) {
      pkg.addEventListener("change", updateSummary);
    }

    // ---- Индийские цены по гражданству ----
    // Для граждан Индии/Непала подставляем в селект тарифа цены custom_20
    // (data-india-*). Окончательную цену считает сервер (Invitation#set_price).
    var country = document.getElementById("countrySelect");
    var indiaNote = document.getElementById("invIndiaNote");
    var indiaCodes = country ? (country.getAttribute("data-india-codes") || "").split(/\s+/) : [];
    function applyCitizenPrices() {
      if (!pkg || !country) { updateSummary(); return; }
      var india = indiaCodes.indexOf((country.value || "").toUpperCase()) !== -1;
      var switched = false;
      Array.prototype.forEach.call(pkg.options, function (opt) {
        var indiaPrice = opt.getAttribute("data-india-price");
        if (!indiaPrice) return;
        if (opt.getAttribute("data-default-price") === null) {
          opt.setAttribute("data-default-price", opt.getAttribute("data-price") || "");
          opt.setAttribute("data-default-text", opt.textContent);
        }
        if (india) {
          opt.setAttribute("data-price", indiaPrice);
          opt.textContent = opt.getAttribute("data-india-text");
          switched = true;
        } else {
          opt.setAttribute("data-price", opt.getAttribute("data-default-price"));
          opt.textContent = opt.getAttribute("data-default-text");
        }
      });
      if (indiaNote) indiaNote.hidden = !switched;
      updateSummary();
    }
    if (country) country.addEventListener("change", applyCitizenPrices);
    applyCitizenPrices();

    // ---- Отправка ----
    function resetSubmit() {
      submitting = false;
      if (!submitBtn) return;
      submitBtn.disabled = false;
      submitBtn.removeAttribute("aria-busy");
      if (submitBtn.dataset.idleText) submitBtn.textContent = submitBtn.dataset.idleText;
    }

    form.addEventListener("submit", function (e) {
      if (submitting) { e.preventDefault(); return; }

      var invalid = fields().filter(function (el) { return !validateField(el); });

      // Turnstile: если виджет загрузился, но проверка ещё не пройдена — подсказываем.
      var cfInput = form.querySelector('input[name="cf-turnstile-response"]');
      var cfMissing = cfInput && !cfInput.value;

      if (invalid.length || cfMissing) {
        e.preventDefault();
        if (errorSummary) {
          errorSummary.textContent = invalid.length
            ? "Please check the highlighted fields (" + invalid.length + ")."
            : "Please complete the security check above the button.";
          errorSummary.hidden = false;
        }
        var target = invalid.length ? invalid[0] : form.querySelector(".inv-turnstile");
        var wrap = invalid.length ? fieldWrap(target) : target;
        if (wrap) wrap.scrollIntoView({ block: "center", behavior: "smooth" });
        if (invalid.length) {
          var f = focusTarget(target);
          if (f) setTimeout(function () { f.focus({ preventScroll: true }); }, 300);
        }
        return;
      }

      if (errorSummary) errorSummary.hidden = true;
      submitting = true;
      if (submitBtn) {
        submitBtn.dataset.idleText = submitBtn.textContent.trim();
        submitBtn.textContent = submitBtn.dataset.sendingText || "Sending…";
        submitBtn.setAttribute("aria-busy", "true");
        // disabled ставим после того, как браузер начал отправку, иначе он
        // не уйдёт в некоторых браузерах; повторные сабмиты гасит флаг submitting.
        setTimeout(function () { submitBtn.disabled = true; }, 0);
      }
    });

    // Возврат «Назад» из bfcache — кнопка снова активна.
    window.addEventListener("pageshow", function (e) { if (e.persisted) resetSubmit(); });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () { setTimeout(init, 0); });
  } else {
    setTimeout(init, 0);
  }
})();
