(function($, undefined) {
  function OrgChartMenuNodeCreation() {};

  window.OrgChartMenuNodeCreation = OrgChartMenuNodeCreation;

  var proto = OrgChartMenuNodeCreation.prototype;

  proto.onAddNodes = function() {
    // Get the values of the new nodes and add them to the nodeVals array
    var newNodeName = $('#new-node').val().trim();

    // Get the data of the currently selected node
    var $node = $('#selected-node').data('node');

    if (newNodeName.length == 0 || !$node) {
      return;
    }
    this.createNode(newNodeName, $node[0].id).then($.proxy(this.onCreateNode, this), $.proxy(this.onErrorCreateNode, this));
    $('#new-node').val('');
  };

  proto.onErrorCreateNode = function(error) {
    error.responseJSON.errors.forEach($.proxy(function(error) {
      this.alert(error.detail);
    }, this));
  };

  proto.onCreateNode = function (response) {
    // See https://github.com/dabeng/OrgChart#structure-of-datasource
    var relationship = '';
    var id = response['data']['id'];

    $node.attr('id', id);
    if (!this.hasChildren($node)) {
      // Relationship will always be "has parent, no siblings, no children"
      relationship = '100'

      /*$('#chart-container').orgchart('addChildren', $node, {
        'children': [{ name: newNodeName, relationship: relationship, id: id }]
      });*/
      $('#chart-container').orgchart('addChildren', $node, {
        'children': [{ name: newNodeName, relationship: relationship, id: id }]
      });    
    } else {
      // Relationship will always be "has parent, has sibling(s), no children"
      relationship = '110'

      $('#chart-container').orgchart('addSiblings', $node.closest('tr').siblings('.nodes').find('.node:first'),
        {
          'siblings': [{
            'name': newNodeName,
            'relationship': relationship,
            'id': id
          }]
        }
      );
    }
  };

  proto.createNode = function(newName, parentId) {
    return this.keepTreeUpdate().then($.proxy(function() {
      return $.ajax({
        headers : {
            'Accept' : 'application/vnd.api+json',
            'Content-Type' : 'application/vnd.api+json'
        },
        url : '/api/v1/nodes/',
        type : 'POST',
        data : JSON.stringify({ data: { type: 'nodes', attributes: { name: newName}, relationships: { parent: { data: { type: 'nodes', id: parentId }}} }})
      }).fail($.proxy(onErrorConnection, this));
    }, this));
  };

}(jQuery));
