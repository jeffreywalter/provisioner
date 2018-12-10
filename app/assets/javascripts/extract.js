$('#company_select').click(function() {
  $('.analyze').hide();
});

$('#company_select').change(function() {
  var company_id = this.value;
  $('#company_loader').toggle();
  source = new EventSource("/extract/properties?company_id="+company_id);
  source.onmessage = function(e) {
    var data = JSON.parse(e.data),
    property_select = $('#source_property_select');
    property_select.children('option:not(:first)').remove()
    data.forEach(function(element) {
      option = document.createElement('option');
      option.text = element[0];
      option.value = element[1];
      property_select[0].add(option)
    });
    $('.analyze').toggle();
    $('#company_loader').toggle();
  }
  source.onerror = function(event){
    var txt;
    switch( event.target.readyState ){
        // if reconnecting
      case EventSource.CONNECTING:
        txt = 'Closing...';
        break;
        // if error was fatal
      case EventSource.CLOSED:
        txt = 'Connection failed. Will not retry.';
        break;
    }
    console.log(txt);
    source.close();
  }
});

$('#source_property_select').on('change', function() {
  var property_id = this.value,
    analyses_table = $('#analyses_table');
  $('#property_loader').show()
  $(analyses_table).children().remove();
  if (property_id == undefined || property_id == '' ) {
    // alert("Please select a property.");
    return;
  };
  source = new EventSource("/extract/analyses?property_id="+property_id);
  source.onmessage = function(e) {
    var button = $('div#start_analysis');
    $('div#analyses_table').append($.parseHTML(e.data));
     $(button).show();
    window.scrollTo(0, document.body.scrollHeight);
    $('#property_loader').toggle();
  };
  source.onerror = function(event){
      var txt;
      switch( event.target.readyState ){
          // if reconnecting
          case EventSource.CONNECTING:
              txt = 'Closing...';
              break;
          // if error was fatal
          case EventSource.CLOSED:
              txt = 'Connection failed. Will not retry.';
              break;
      }
    console.log(txt);
    source.close();
  }
});

$('#start_analysis').on('click', function() {
  var property_id = $('#source_property_select').val();
    analyses_table = $('#analyses_table');
  if (property_id == undefined || property_id == '' ) {
    alert("Please select a property.");
    return;
  };
  $('#analysis_loader').toggle();
  source = new EventSource("/extract/analyze?property_id="+property_id);
  source.onmessage = function(e) {
    $(analyses_table).children().remove();
    $('#analysis_loader').toggle();
    $('div#analyses_table').append($.parseHTML(e.data));
  }
  source.onerror = function(event){
      var txt;
      switch( event.target.readyState ){
          // if reconnecting
          case EventSource.CONNECTING:
              txt = 'Closing...';
              break;
          // if error was fatal
          case EventSource.CLOSED:
              txt = 'Connection failed. Will not retry.';
              break;
      }
    console.log(txt);
    source.close();
  }
});

$('#start_proto').on('click', function() {
  var extension_name = $('#target_extension_name').val();
  if (extension_name == undefined || extension_name == '' ) {
    alert("Please enter a target extension name.");
    return;
  };
  source = new EventSource("/extract/proto?extract_id="+_extract_id+"&extension_name="+extension_name);
  source.onmessage = function(e) {
    console.log(e.data)
    window.location = e.data
  }
  source.onerror = function(event){
      var txt;
      switch( event.target.readyState ){
          // if reconnecting
          case EventSource.CONNECTING:
              txt = 'Closing...';
              break;
          // if error was fatal
          case EventSource.CLOSED:
              txt = 'Connection failed. Will not retry.';
              break;
      }
    console.log(txt);
    source.close();
  }
});
