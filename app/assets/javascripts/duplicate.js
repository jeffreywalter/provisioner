$('#company_select').change(function() {
  var company_id = this.value;
  $('.loader').toggle();
  source = new EventSource(`/duplicate/properties?company_id=${company_id}`);
  source.onmessage = function(e) {
    var data = JSON.parse(e.data),
    property_select =  $('#source_property_select')[0];
    data.forEach(function(element) {
      option = document.createElement('option');
      option.text = element[0];
      option.value = element[1];
      property_select.add(option)
    });
    $('.duplicate').toggle();
    $('.loader').toggle();
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

$('#start_duplicate').on('click', function() {
  var property_name = $('#target_property_name').val(),
  property_id = $('#source_property_select').val();
  if (property_id == undefined || property_id == '' ) {
    alert("Please enter a source property.");
    return;
  };
  if (property_name == undefined || property_name == '' ) {
    alert("Please enter a target property name.");
    return;
  };
  source = new EventSource(`/duplicate/stream?source_property_id=${property_id}&target_property_name=${property_name}`);
  source.onmessage = function(e) {
    $('#duplicate_events').append($.parseHTML(e.data));
    window.scrollTo(0, document.body.scrollHeight);
    new Foundation.Accordion($('#duplicate_events'), {allowAllClosed: true});
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
