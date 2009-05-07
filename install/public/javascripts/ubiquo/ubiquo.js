document.observe("dom:loaded", function() {
    //content corners
    if ($('content')){
	$('content').insert({bottom: '<span class="corner_tl"></span><span class="corner_tr"></span><span class="corner_bl"></span><span class="corner_br"></span>'});
    }
    //form_box corners
    if ($$('.form_box').first()){
	$$('.form_box').each(function(f){
            f.insert({bottom: '<span class="corner_tl"></span><span class="corner_tr"></span><span class="corner_bl"></span><span class="corner_br"></span>'});
        });
    }
    
    if($('send_confirm_creation') && $("welcome_message_block")){
        $('send_confirm_creation').observe("change", function(){
            ($('send_confirm_creation').checked ? Effect.BlindDown : Effect.BlindUp)("welcome_message_block")
        });
        if($('send_confirm_creation').checked){
            $("welcome_message_block").show();
        }else{
            $("welcome_message_block").hide();
        }
    }
});

function send_as_form(div_id, url, method){  
	var fo=$(div_id);
  	var ie=(navigator.appVersion.indexOf("MSIE")!=-1);
	var f;
  	if(ie){
	  f = $(document.createElement('<form enctype="multipart/form-data">'));
	}else{
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

function killeditor(){
    if($('visual_editor')){
        tinyMCE.triggerSave(true,true);
        tinyMCE.execCommand( 'mceRemoveControl', true, 'visual_editor');
    }
}

function reviveEditor(){
	if($('visual_editor')){
        tinyMCE.execCommand( 'mceAddControl', true, 'visual_editor');
    }
}

function blind_toggle(desired_elem, brother){
	if($(desired_elem).visible()){
		new Effect.BlindUp($(desired_elem));
	}else{
		new Effect.BlindUp($(brother));
		new Effect.BlindDown($(desired_elem));
	}
}
