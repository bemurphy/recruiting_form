$('#new-job-posting').on('submit', function(e){
  e.preventDefault();

  var success = function(data) {
    window.location = "/thanks";
  };

  var error = function(xhr, status, error) {
    console.log(error);
    console.log(xhr.responseJSON);
  };

  var formData = $(this).serialize();

  $.ajax({
    type: 'POST',
    url: '/jobs',
    data: formData,
    success: success,
    error: error,
    dataType: 'json'
  });
});
