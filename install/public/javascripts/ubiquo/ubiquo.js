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

  // Prepare Hints with help info for form fields (ubiquo_form_builder)
  $$('.form-help .content').each(function(div_fh){
    div_fh.insert("<span class='arrow'></span>");
  });
  Event.observe(document, 'keydown', function(event){
    if(event.keyCode == Event.KEY_ESC){
      $$('.form-help').each(function(div_fh){
        div_fh.removeClassName('active');
      });
    }
  })

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

/*****
 *  ubiquo_settings
 */
function addSettingValue(element){
  var new_element = $(element).previous().cloneNode(true);
  new_element.select('input').first().value = '';
  element.insert({before: new_element});
}
function removeSettingValue(element){
  $(element).ancestors().first().remove();
}
function isSelect(dom, settingKey){
  return (dom.getElementsBySelector('input[name="' + settingKey + '"]').length == 0
    && dom.getElementsBySelector('select[name="' + settingKey + '"]').length)
}
function isTextArea(dom, settingKey){
  return dom.getElementsBySelector('textarea[name="' + settingKey + '"]').length;
}
function isMultipleInput(dom, settingKey){
  return   dom.getElementsBySelector('input[name="' + settingKey + '[]"]').length;
}
function isMultipleForSelect(dom, settingKey){
  return dom.getElementsBySelector('select[name="' + settingKey + '[]"]').length;
}
function isSingleIput(dom, settingKey){
  return dom.getElementsBySelector('input[name="' + settingKey + '[]"]').length;
}
function isCheckbox(dom, settingKey){
  var input = dom.getElementsBySelector('input[name="' + settingKey + '"]').first();
  return input && input.type == 'checkbox' && input.checked == true
}
function isPassword(dom, settingKey){
  var input = dom.getElementsBySelector('input[name="' + settingKey + '"]').first();
  var hidden_input = dom.getElementsBySelector('input[name="confirmation_' + settingKey + '"]').first()
  return input && input.type == 'password' && hidden_input
}
function addHiddenFieldsForSettings(form, settings, selectedSettingKey){
  for(var context in settings) {
    for(var settingKey in settings[context]) {
      if(selectedSettingKey == null || settingKey == selectedSettingKey){
        var hiddenField = document.createElement("input");
        var hiddenFieldName;
        hiddenField.setAttribute("type", "hidden");
        // is a array, change the name and add one hidden input for each value
        if(typeof settings[context][settingKey].first === 'function'){
          hiddenFieldName = "ubiquo_settings" + "[" + context + "[" + settingKey + "][]"
          hiddenField.setAttribute("name", hiddenFieldName)
          $(settings[context][settingKey]).each(function(s) {
            hiddenField.value = s;
            $(form).appendChild(hiddenField.cloneNode(true));
          })
        } else {
          hiddenFieldName = "ubiquo_settings" + "[" + context + "[" + settingKey + "]]"
          hiddenField.setAttribute("name", hiddenFieldName)
          hiddenField.setAttribute("value", settings[context][settingKey]);
          $(form).appendChild(hiddenField.cloneNode(true));
        }
      }
    }
  }
}
function collectAndSendValues(selectedContext, selectedSettingKey){
  var settings = {}
  var contexts = $$('#contexts > table');
  for(var i = 0; i < contexts.length; ++i){
    var contextKey = $(contexts[i]).readAttribute('id')
    if(selectedContext == null || contextKey == selectedContext ){
      settings[contextKey] = {}
      var settingsRows = $(contexts[i]).getElementsBySelector('tbody tr');
      for(var j = 0; j < settingsRows.length; ++j){
        var settingKey = settingsRows[j].readAttribute('id');
        settingKey = settingKey.replace('ubiquo_setting_','');
        if(selectedSettingKey == null || settingKey == selectedSettingKey){

          var settingValue;
          if(isSelect(settingsRows[j], settingKey)){
            settingValue = settingsRows[j].getElementsBySelector('select[name="' + settingKey + '"]').first().value;
          }
          else if(isTextArea(settingsRows[j], settingKey)){
            settingValue = settingsRows[j].getElementsBySelector('textarea[name="' + settingKey + '"]').first().value;
          }
          else if(isMultipleInput(settingsRows[j], settingKey)){
            settingValue = settingsRows[j].getElementsBySelector('input[name="' + settingKey + '[]"]').collect(function(s) {
              return s.value
            })
          }
          else if(isMultipleForSelect(settingsRows[j], settingKey)){
            settingValue = settingsRows[j].getElementsBySelector('select[name="' + settingKey + '[]"]').first().getValue();
          }
          // Is single a input
          else {
            if(isCheckbox(settingsRows[j], settingKey)){
              settingValue = false;
            } else if(isPassword(settingsRows[j], settingKey)){
              settingValue = settingsRows[j].getElementsBySelector('input[name="' + settingKey + '"]').first().value;
              var confirmationKey = "confirmation_" + settingKey;
              var confirmationValue = settingsRows[j].getElementsBySelector('input[name="confirmation_' + settingKey + '"]').first().value;
              settings[contextKey][confirmationKey] = confirmationValue;
            } else {
              var input = settingsRows[j].getElementsBySelector('input[name="' + settingKey + '"]').first()
              if(input){
                settingValue = input.value;
              }
            }
          }
          settings[contextKey][settingKey] = settingValue;
        }
      }
    }
  }
  var form = $('bulk_submit');
  addHiddenFieldsForSettings(form, settings);
  form.submit();
}