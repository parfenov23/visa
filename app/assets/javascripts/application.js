//= require jquery
//= require_tree .
$(document).ready(function(){
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
  // CREATE PERSON TEMPLATE
  // ---------------------------------------------------------
    function createPersonBlock() {
      return $(`
      <div class="person border p-3 mb-3 rounded bg-light">
        <button type="button" class="close removePerson">&times;</button>
        <h4>Person:</h4>

        <div class="row">
          <div class="col">
            <div class="form-group">
              <label>Surname*</label>
              <input type="text" class="form-control" name="surname">
            </div>
          </div>

          <div class="col">
            <div class="form-group">
              <label>Name</label>
              <input type="text" class="form-control" name="name">
            </div>
          </div>

          <div class="col">
            <div class="form-group">
              <label>Middle name</label>
              <input type="text" class="form-control" name="middlename">
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col">
            <div class="form-group">
              <label>Sex*</label>
              <select class="form-control" name="sex">
                <option value="-1">-</option>
                <option value="0">Female</option>
                <option value="1">Male</option>
              </select>
            </div>
          </div>

          <div class="col">
            <div class="form-group">
              <label>Date of birth*</label>
              <input type="date" class="form-control" name="birthDate">
            </div>
          </div>
        </div>

        <div class="row">
          <div class="col">
            <div class="form-group">
              <label>Citizenship*</label>
              <input type="text" class="form-control" name="citizenship">
            </div>
          </div>

          <div class="col">
            <div class="form-group">
              <label>Passport*</label>
              <input type="text" class="form-control" name="passport">
            </div>
          </div>

          <div class="col">
            <div class="form-group">
              <label>Passport expire date</label>
              <input type="date" class="form-control" name="passportExpire">
            </div>
          </div>
        </div>
      </div>
      `);
    }

  // ---------------------------------------------------------
  // DOCUMENT READY
  // ---------------------------------------------------------
    $(function () {

      $("#addPerson").on("click", function (e) {
        e.preventDefault();
        $("#persons").append(createPersonBlock());
      });

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
