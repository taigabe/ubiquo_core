//clas
// LightWindow for ubiquo
//
// We redefine the function that inits the lightwindow with the custom parameters
//
var myLightWindow = null;

tinyMceLightWindow = Class.create( lightwindow,{
    // TinyMCE
    _putTinyMCE: function(reference){
        $$("."+reference+", #"+reference).each(function(v) {
            tinyMCE.execCommand('mceAddControl', true, $(v).id);
        });
    },
    _processWindow: function($super){
        $super();
        this._putTinyMCE('visual_editor');
    },
    deactivate: function($super){
        killeditor();
        var classname = this._getParameter("lightwindow_class");
        if(classname){
            $('lightwindow').removeClassName(classname);
        }
        $super();
    },
    _setupWindowElements: function( $super, link){
        $super(link);
        var classname = this._getParameter("lightwindow_class");
        if(classname){
            $('lightwindow').addClassName(classname);
        }
    }
});

window["lightwindowInit"] = function() {
	myLightWindow = new tinyMceLightWindow({
        dimensions : {
           image : {height : 250, width : 600},
           page : {height : 250, width : 600},
           inline : {height : 250, width : 600},
           media : {height : 250, width : 600},
           external : {height : 250, width : 600},
           titleHeight: 25
        },
        skin : 	{
            main : '<div id="lightwindow_container" >'+
                                                        '<div id="lightwindow_title_bar" >'+
                                                                '<div id="lightwindow_title_bar_inner" >'+
                                                                        '<span id="lightwindow_title_bar_title" style="display:none;"></span>'+

                                                                '</div>'+
                                                        '</div>'+
                                                        '<div id="lightwindow_stage" >'+
                                                                '<div id="ubiquo_lb">'+
                                                                        '<div id="lightwindow_contents" >'+
                                                                        '</div>'+
                                                                '</div>'+
                                                                '<div id="lightwindow_navigation" >'+
                                                                        '<a href="#" id="lightwindow_previous" >'+
                                                                                '<span id="lightwindow_previous_title"></span>'+
                                                                        '</a>'+
                                                                        '<a href="#" id="lightwindow_next" >'+
                                                                                '<span id="lightwindow_next_title"></span>'+
                                                                        '</a>'+
                                                                        '<iframe name="lightwindow_navigation_shim" id="lightwindow_navigation_shim" src="javascript:false;" frameBorder="0" scrolling="no"></iframe>'+
                                                                '</div>'+
                                                                '<div id="lightwindow_galleries">'+
                                                                        '<div id="lightwindow_galleries_tab_container" >'+
                                                                                '<a href="#" id="lightwindow_galleries_tab" >'+
                                                                                        '<span id="lightwindow_galleries_tab_span" class="up" >Galleries</span>'+
                                                                                '</a>'+
                                                                        '</div>'+
                                                                        '<div id="lightwindow_galleries_list" >'+
                                                                        '</div>'+
                                                                '</div>'+
                                                                '<div class="inferior" />'+
                                                        '</div>'+
                                                        '<div id="lightwindow_data_slide" >'+
                                                                '<div id="lightwindow_data_slide_inner" >'+
                                                                        '<div id="lightwindow_data_details" >'+
                                                                                '<div id="lightwindow_data_gallery_container" >'+
                                                                                        '<span id="lightwindow_data_gallery_current"></span>'+
                                                                                        ' of '+
                                                                                        '<span id="lightwindow_data_gallery_total"></span>'+
                                                                                '</div>'+
                                                                                '<div id="lightwindow_data_author_container" >'+
                                                                                        'by <span id="lightwindow_data_author"></span>'+
                                                                                '</div>'+
                                                                        '</div>'+
                                                                        '<div id="lightwindow_data_caption" >'+
                                                                        '</div>'+
                                                                '</div>'+
                                                        '</div>'+
                                                '</div>',
            loading : '<div id="lightwindow_loading" >'+
								'<img src="/images/ubiquo/lightwindow/ajax-loading.gif" alt="loading" />'+
								'<span>Loading or <a href="javascript: myLightWindow.deactivate();">Cancel</a></span>'+
								'<iframe name="lightwindow_loading_shim" id="lightwindow_loading_shim" src="javascript:false;" frameBorder="0" scrolling="no"></iframe>'+
							'</div>',
            iframe : 	'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'+
                        '<html xmlns="http://www.w3.org/1999/xhtml">'+
                            '<body>'+
                                '{body_replace}'+
                            '</body>'+
                        '</html>',
            gallery : {
                top :		'<div class="lightwindow_galleries_list">'+
                                '<h1>{gallery_title_replace}</h1>'+
                                '<ul>',
                middle : 			'<li>'+
                                        '{gallery_link_replace}'+
                                    '</li>',
                bottom : 		'</ul>'+
                            '</div>'
            }
        },
        //
        //  Finish up Window Animation Replacement (copy&change from lightwindow.js#_handleFinalWindowAnimation)
        //
        finalAnimationHandler : function(delay) {
            if (this.windowType == 'media' || this._getParameter('lightwindow_loading_animation')) {
                // Because of major flickering with the overlay we just hide it in this case
                Element.hide('lightwindow_loading');
                this._handleNavigation(this.activeGallery);
                this._setStatus(false);
            } else {
                Effect.Fade('lightwindow_loading', {
                    duration: 0,
                    delay: 0,
                    afterFinish: function() {
                        // Just in case we need some scroll goodness (this also avoids the swiss cheese effect)
                        if (this.windowType != 'image' && this.windowType != 'media' && this.windowType != 'external') {
                            $('lightwindow_contents').setStyle({
                                overflow: 'auto'
                            });
                        }
                        this._handleNavigation(this.activeGallery);
                        this._defaultGalleryAnimationHandler();
                        this._setStatus(false);
                    }.bind(this),
                    queue: {position: 'end', scope: 'lightwindowAnimation'}
                });
            }
        }

    });
    myLightWindow.duration = 0;
}

Event.observe(window, 'load', lightwindowInit, false);

