!function($){

  function datePicker(options){
    var oldDatePicker = this.find('span.date-picker-holder');
    if (oldDatePicker) {
      oldDatePicker.remove();
    }

    var monthes = [
      '01-January',
      '02-February',
      '03-March',
      '04-April',
      '05-May',
      '06-June',
      '07-July',
      '08-August',
      '09-September',
      '10-October',
      '11-November',
      '12-December'
    ];
    var days = [
      31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
    ];

    function leapYear(year){
      return ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function fillDays(){
      var oldDay = datePicker.date;
      dateSelect.children().remove();
      dateSelect.append('<option value="">Day:</option>');
      var daysCount = days[datePicker.month || 0];
      if (datePicker.month === 1 && leapYear(datePicker.year)) {
        daysCount++;
      }
      if (oldDay > daysCount) {
        oldDay = 1;
      }

      for (var d = 1; d <= daysCount; d++) {
        dateSelect.append('<option value="' + d + '">' + d + '</option>');
      }
      dateSelect.val(oldDay);
      datePicker.date = oldDay;
    }

    if (!options) {
      options = {};
    }

    var datePicker = {};

    var input = $(this);
    input.hide();
    const oldVal = input.val();

    var span = $('<span class="date-picker-holder"></span>');

    var dateSelect = $('<select aria-label="Day" class="form-control" style="display: inline; width: 20%; margin-right: 5px;" ' + (options.required ? 'required' : '') + '></select>');
    var monthSelect = $('<select aria-label="Month" class="form-control" style="display: inline; width: 35%; margin-right: 5px;" ' + (options.required ? 'required' : '') + '></select>');
    var yearSelect = $('<select aria-label="Year" class="form-control" style="display: inline; width: 35%; margin-right: 5px;" ' + (options.required ? 'required' : '') + '></select>');

    monthSelect.append('<option value="">Month:</option>');
    for (var m = 0; m < 12; m++) {
      monthSelect.append('<option value="' + m + '">' + monthes[m] + '</option>');
    }

    function setCurrentValue(){
      if (datePicker.date != null && datePicker.month != null && datePicker.year != null) {
        var r = ('00' + datePicker.date).slice(-2) + '.' + ('00' + (datePicker.month + 1)).slice(-2) + '.' + datePicker.year;
        input.val(r);
      } else {
        input.val('');
      }
    }

    monthSelect.change(function(){
      var newValue = monthSelect.val();
      if (newValue != null && newValue !== '') {
        datePicker.month = +newValue;
      } else {
        datePicker.month = null;
      }
      fillDays();
      setCurrentValue();
    });

    yearSelect.change(function(){
      var newValue = yearSelect.val();
      if (newValue != null && newValue !== '') {
        datePicker.year = +newValue;
      } else {
        datePicker.year = null;
      }
      fillDays();
      setCurrentValue();
    });

    dateSelect.change(function(){
      var newValue = dateSelect.val();
      if (newValue != null && newValue !== '') {
        datePicker.date = +newValue;
      } else {
        datePicker.date = null;
      }
      setCurrentValue();
    });

    span.append(dateSelect);
    span.append(monthSelect);
    span.append(yearSelect);
    this.after(span);

    datePicker.setYearRange = function(start, end){
      yearSelect.children().remove();
      if (start > end) {
        throw new Error('year range start must be greater than end');
      }
      yearSelect.append('<option value="">Year:</option>');
      for (var year = end; year >= start; year--) {
        yearSelect.append('<option value="' + year + '">' + year + '</option>');
      }
    }
    if (options.startYear && options.endYear) {
      datePicker.setYearRange(options.startYear, options.endYear);
    }

    datePicker.setDate = function(date){
      datePicker.date = date.getDate();
      datePicker.month = date.getMonth();
      datePicker.year = date.getFullYear();
      yearSelect.val(date.getFullYear());
      monthSelect.val(date.getMonth());
      dateSelect.val(date.getDate());
      yearSelect.change();
      monthSelect.change();
      dateSelect.change();
    }

    if (options.date) {
      datePicker.setDate(options.date);
    } else if (oldVal) {
      var parts = oldVal.split('.');
      if (parts.length === 3) {
        datePicker.setDate(new Date(+parts[2], +parts[1] - 1, +parts[0]));
      }
    }

    fillDays();
    datePicker.getDate = function(){
      return new Date(datePicker.year, datePicker.month, datePicker.date);
    }

    $(this).addClass('date-picker');
    $(this).data('date-picker', datePicker);

    return this;
  };

  $.fn.datePicker = datePicker;

}(jQuery);