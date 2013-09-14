$('#new-job-posting').on('submit', function(e){
  e.preventDefault();

  var form = $(this);
  var errClass= 'has-error';

  var success = function(data) {
    window.location = "/thanks";
  };

  $('.form-group').removeClass(errClass);

  var error = function(xhr, status, error) {
    var obj = xhr.responseJSON;

    for (var key in obj) {
      if (obj.hasOwnProperty(key)) {
        form.find('[name="' + key + '"]')
          .closest('.form-group')
          .addClass(errClass);
      }
    }
  };

  var formData = form.serialize();

  $.ajax({
    type: 'POST',
    url: '/jobs',
    data: formData,
    success: success,
    error: error,
    dataType: 'json'
  });
});
