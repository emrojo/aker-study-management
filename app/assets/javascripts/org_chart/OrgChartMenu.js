(function($, undefined) {
  
  function OrgChartMenu() {
    this.resetStatusMenu();
    this.attachMenuHandlers();
  };

  window.OrgChartMenu = OrgChartMenu;

  var MODULES = [
    OrgChartMenuNodeCreation, 
    OrgChartMenuNodeDelete, 
    OrgChartMenuNodeUpdate
  ];

  OrgChartMenu.prototype = $.extend.apply(this, $.map(MODULES, function(mod) { return mod.prototype; }));

  var proto = OrgChartMenu.prototype;

  proto.resetStatusMenu = function() {
    $('#edit-panel button').prop('disabled', true);
    $('#edit-panel input').prop('disabled', true);
    $('#edit-panel input').val('')
    $('#selected-node').val('');    
  };


  proto.attachMenuHandlers = function() {
    $('#btn-add-nodes').on('click', $.proxy(this.onAddNodes, this));
    // Delete Button
    $('#btn-delete-nodes').on('click', $.proxy(this.onDeleteNodes, this));
    // Reset Button
    $('#btn-reset').on('click', $.proxy(this.onResetNodes, this));
    $('#editNodeModal').on('show.bs.modal', $.proxy(this.onUpdateNodes, this));    
  };
  
  proto.onResetNodes = function() {
    $('#selected-node').data('node', null).val('');
    $('#new-node').val('');
  };
  
}(jQuery));