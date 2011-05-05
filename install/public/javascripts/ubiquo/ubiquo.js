document.observe("dom:loaded", function() {
  //action buttons
  var num_buttons = 0;
  $$('#content tr').each(function(e,index) {
    if(index == 0){
      //first row (headers)
      e.insert({
        bottom: '<th class="delete">&nbsp;</th>'
      });
    }else{
      var edit_btn = e.down('.btn-edit');
      edit_btn.hide();
      var del_btn = e.down('.btn-delete');
      del_btn.update('<span>'+del_btn.text+'</span>');
      del_btn.remove();
      e.insert('<td class="delete"></td>');
      e.down('td.delete').insert(del_btn);
      del_btn.observe('click', function(ev){
        Event.stop(ev);
      });
      
      var edit_url = null;
      if(edit_btn != undefined) edit_url = edit_btn.readAttribute('href');
      
      e.writeAttribute('title',edit_btn.readAttribute('title'));
      
      e.observe('mouseover', function(ev){
        e.addClassName('hover');
      });
      e.observe('mouseout', function(ev){
        e.removeClassName('hover');
      });
      e.observe('click', function(ev){
        if (edit_url != null) window.location.href = edit_url;
      });
      num_buttons = e.down('.actions').childElements().length;
    }
  });
  if(num_buttons < 2){
    $$('#content tr .actions').each(function(e){
      e.remove();
    });
  }

  //ubiquo_authentication
  if($('send_confirm_creation') && $("welcome_message_block")) {
    $('send_confirm_creation').observe("change", function() {
      if ($('send_confirm_creation').checked) {
        Effect.BlindDown("welcome_message_block");
      } else {
        Effect.BlindUp("welcome_message_block");
      }
    });
    if($('send_confirm_creation').checked) {
      $("welcome_message_block").show();
    } else {
      $("welcome_message_block").hide();
    }
  }
  //ubiquo_i18n
  if($('locale_selector') != undefined) {
    var locale_selector = $('locale_selector');
    locale_selector.observe(
      "change",
      function(){
        this.up('form').submit();
      }
    );
  }
});

function send_as_form(div_id, url, method) {
  var fo = $(div_id);
  var ie = navigator.appVersion.indexOf("MSIE") != -1;
  var f;
  if(ie) {
    f = $(document.createElement('<form enctype="multipart/form-data">'));
  } else {
    f = document.createElement('form');
    f.enctype= 'multipart/form-data';
  }
  f.action = url;
  f.target = 'upload_frame';
  f.method = method;
  f.setAttribute('style', 'display = "hidden"');
  document.getElementsByTagName('body')[0].appendChild(f);
  f.appendChild(fo);
  f.submit();
  f.remove();
}

function killeditor(reference) {
  reference = reference || 'visual_editor';
  var first = true;
  $$("."+reference+", #"+reference).each(function(v) {
    if(first) {
      tinyMCE.triggerSave(true,true);
      first = false;
    }
    tinyMCE.execCommand('mceRemoveControl', true, $(v).id);
  });
}

function reviveEditor(reference) {
  reference = reference || 'visual_editor';
  $$("."+reference+", #"+reference).each(function(v) {
    tinyMCE.execCommand('mceAddControl', true, $(v).id);
  });
}

function blind_toggle(desired_elem, brother) {
  if($(desired_elem).visible()) {
    new Effect.BlindUp($(desired_elem));
  } else {
    new Effect.BlindUp($(brother));
    new Effect.BlindDown($(desired_elem));
  }
}

/*
 * Registers a callback which copies the csrf token into the
 * X-CSRF-Token header with each ajax request. Necessary to
 * work with rails applications which have fixed
 * CVE-2011-0447
 */

Ajax.Responders.register({
  onCreate: function(request) {
    var csrf_meta_tag = $$('meta[name=csrf-token]')[0];

    if (csrf_meta_tag) {
      var header = 'X-CSRF-Token',
          token = csrf_meta_tag.readAttribute('content');

      if (!request.options.requestHeaders) {
        request.options.requestHeaders = {};
      }
      request.options.requestHeaders[header] = token;
    }
  }
});

