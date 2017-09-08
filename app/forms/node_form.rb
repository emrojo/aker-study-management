class NodeForm

  # ActiveModel plumbing to make `form_for` work
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  def persisted?
    false
  end

  ATTRIBUTES = [:id, :parent_id, :name, :description, :cost_code, :user_writers, :group_writers, :user_spenders, :group_spenders]

  attr_accessor *ATTRIBUTES

  def initialize(attributes = {})
    ATTRIBUTES.each do |attribute|
      value = attributes[attribute]
      send("#{attribute}=", value)
    end
    @owner = attributes[:owner]
  end

  def save
    # valid? currently does nothing
    valid? && (id.present? ? update_objects : create_objects)
  end

  def self.from_node(node)
    new(id: node.id, parent_id: node.parent_id, name: node.name, description: node.description,
        cost_code: node.cost_code, owner: node.owner,
        user_writers: node_permitted(node, :write, false),
        group_writers: node_permitted(node, :write, true),
        user_spenders: node_permitted(node, :spend, false),
        group_spenders: node_permitted(node, :spend, true))
  end

  def error_messages
    @node.errors
  end

private

  def self.node_permitted(node, permission_type, groups)
    permission_type = permission_type.to_sym
    perms = node.permissions.select { |p| p.permission_type.to_sym==permission_type && p.permitted.include?('@')!=groups }.
      map { |p| p.permitted }
    if !groups && node.owner&.email
      perms.delete(node.owner.email.downcase)
    end
    perms.join(',')
  end

  def create_objects
    ActiveRecord::Base.transaction do
      @node = Node.new(name: name, cost_code: cost_code, description: description, parent_id: parent_id, owner: @owner)
      if @node.save
        @node.permissions.create!(convert_permissions(@owner))
      else
        return false
      end
    end
  rescue
    false
  end

  def update_objects
    ActiveRecord::Base.transaction do
      @node = Node.find(id)
      if @node.update_attributes(name: name, cost_code: cost_code, description: description, parent_id: parent_id)
        @node.permissions.destroy_all
        @node.set_permissions
        @node.permissions.create!(convert_permissions(@node.owner))
      else
        return false
      end
    end
  rescue
    false
  end

  def convert_permissions(owner)
    owner_email = owner&.email&.strip&.downcase
    permitted = []
    add_to_permission(permitted, user_writers, false, :write, owner_email)
    add_to_permission(permitted, group_writers, true, :write, owner_email)
    add_to_permission(permitted, user_spenders, false, :spend, owner_email)
    add_to_permission(permitted, group_spenders, true, :spend, owner_email)
    permitted
  end

  def add_to_permission(permitted, people, is_group, permission_type, owner_email)
    return unless people
    people.split(',').map { |name| fixname(name, is_group) }.
      uniq.
      reject { |name| name==owner_email }.
      each { |name| permitted.push({ permitted: name, permission_type: permission_type })}
  end

  def fixname(name, is_group)
    name = name.strip.downcase
    name += '@sanger.ac.uk' unless (is_group || name.include?('@'))
    return name
  end

end
