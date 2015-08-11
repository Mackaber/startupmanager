/*
 Copyright (c) 2003-2011, CKSource - Frederico Knabben. All rights reserved.
 For licensing, see LICENSE.html or http://ckeditor.com/license
 */

CKEDITOR.editorConfig = function(config) {
  // Define changes to default configuration here. For example:
  // config.language = 'fr';
  // config.uiColor = '#AADC6E';
  
  config.basePath = "/assets/ckeditor";
  
  config.enterMode = CKEDITOR.ENTER_P;
  config.shiftEnterMode = CKEDITOR.ENTER_BR;
  config.baseFloatZIndex = 999999999;

//  /* Filebrowser routes */
//  // The location of an external file browser, that should be launched when "Browse Server" button is pressed.
//  config.filebrowserBrowseUrl = "/ckeditor/attachment_files";
//
//  // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Flash dialog.
//  config.filebrowserFlashBrowseUrl = "/ckeditor/attachment_files";
//
//  // The location of a script that handles file uploads in the Flash dialog.
//  config.filebrowserFlashUploadUrl = "/ckeditor/attachment_files";
//
//  // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Link tab of Image dialog.
//  config.filebrowserImageBrowseLinkUrl = "/ckeditor/pictures";
//
//  // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Image dialog.
//  config.filebrowserImageBrowseUrl = "/ckeditor/pictures";

  // The location of a script that handles file uploads in the Image dialog.
  config.filebrowserImageUploadUrl = "/ckeditor/pictures";

//  // The location of a script that handles file uploads.
//  config.filebrowserUploadUrl = "/ckeditor/attachment_files";
//
//  /* Extra plugins */
//  // works only with en, ru, uk locales
//  config.extraPlugins = "embed,attachment";

  /* Toolbars */
  config.toolbar = "Custom";

  config.toolbar_Custom =
      [
        { name: 'document', items : [ 'Source'] },
        { name: 'basicstyles', items : [ 'Bold','Italic','Underline','Strike' ] },
        { name: 'paragraph', items : [ 'NumberedList','BulletedList', 'Outdent','Indent' ] },
        { name: 'styles', items : [ 'FontSize' ] },
        { name: 'links', items : [ 'Link','Unlink' ] },
        { name: 'insert', items : [ 'Image' ] }
      ];

  config.removePlugins = 'elementspath';
};
