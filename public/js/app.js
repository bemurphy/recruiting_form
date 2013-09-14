var jobPostingForm = function(selector, action) {
  var form = $(selector);
  var btn = form.find('[type="submit"]');
  var errClass= 'has-error';
  var origBtnText = btn.text();
  var submitBtnText = btn.data('disable-with');

  var success = function(data) {
    form.find('.alert').text(data.msg).addClass('alert-success');
    form.addClass('is-success');
  };

  var error = function(xhr, status, error) {
    var obj = xhr.responseJSON;

    for (var key in obj) {
      if (obj.hasOwnProperty(key)) {
        form.find('[name="' + key + '"]')
          .closest('.form-group')
          .addClass(errClass);
      }
    }

    btn.text(origBtnText).attr('disabled', null);
  };

  form.on('submit', function(e) {
    e.preventDefault();

    btn.text(submitBtnText).attr('disabled', 'disabled');
    form.find('.form-group').removeClass(errClass);

    var formData = form.serialize();

    $.ajax({
      type: 'POST',
      url: action,
      data: formData,
      success: success,
      error: error,
      dataType: 'json'
    });
  });
};

jobPostingForm('#new-job-posting', '/jobs');
