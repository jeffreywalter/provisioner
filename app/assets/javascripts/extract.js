$('#company_select').click(function() {
  $('.analyze').hide();
});

$('#company_select').change(function() {
  var company_id = this.value;
  $('.loader').toggle();
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

$('#source_property_select').on('change', function() {
  var property_id = this.value,
  current_events = $('#analyses_events');
  if ($(current_events).children().length > 0) {
    $(current_events).children().remove();
  };
  if (property_id == undefined || property_id == '' ) {
    // alert("Please select a property.");
    return;
  };
  source = new EventSource("/extract/analyses?property_id="+property_id);
  source.onmessage = function(e) {
    $('#analyses_events').append($.parseHTML(e.data));
    window.scrollTo(0, document.body.scrollHeight);
    new Foundation.Accordion($('#analyses_events'), {allowAllClosed: true});
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
  if (property_id == undefined || property_id == '' ) {
    alert("Please select a property.");
    return;
  };
  source = new EventSource("/extract/analyze?property_id="+property_id);
  source.onmessage = function(e) {
    $('#analyses_events').append($.parseHTML(e.data));
    window.scrollTo(0, document.body.scrollHeight);
    new Foundation.Accordion($('#analyses_events'), {allowAllClosed: true});
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
