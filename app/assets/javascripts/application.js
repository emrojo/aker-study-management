// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap-sprockets
//= require_tree .

$(function() {
  $.get('/api/v1/programs?include=projects.aims.proposals', function(response) {
    var treeviewData = buildTree(response.data, response.included);

    $('#tree').treeview({
      data: treeviewData,
      enableLinks: true,
      collapseIcon: 'fa fa-minus',
      expandIcon: 'fa fa-plus',
      emptyIcon: 'fa',
      levels: 1
    })
  });

  $('#project-search').on('keyup', debounce(function(e) {
    var value = $(this).val();

    if (value) {
      $('#tree').treeview('search', [ value, {
        ignoreCase: true,
        exactMatch: false,
        revealResults: true,
      }]);
    } else {
      $('#tree').treeview('clearSearch');
    }
  }, 300))
})
