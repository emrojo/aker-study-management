module Api
  module V1
    class NodesController < JSONAPI::ResourceController
      include JWTCredentials
      include AkerAuthenticationGem::AuthController
  	  include AkerPermissionControllerConfig

      skip_authorization_check only: [:index, :show]

      def create
        authorize! :create, Node, message: 'You are not authorized to create this node.'
        authorize! :write, parent_node unless parent_node.root?
        super
      end

      def destroy
        authorize! :write, current_node, message: 'You are not authorized to delete this node.'
        super
      end

      def update_relationship
        authorize! :write, update_current_node, message: 'You are not authorized to update this node.'
        authorize! :write, update_parent_node unless update_parent_node.root?
        super
      end

      def context
        { current_user: current_user}
      end

      private

      def parent_node
        Node.find_by_id(params[:data][:relationships][:parent][:data][:id])
      end

      def current_node
        @node = (params[:id] && Node.find_by_id(params[:id])) || Node.root
      end

      def update_parent_node
        Node.find_by_id(params[:data][:id])
      end

      def update_current_node
        @node = (params[:node_id] && Node.find_by_id(params[:node_id])) || Node.root
      end

	  end
  end
end
