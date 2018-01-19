require 'rails_helper'
require 'ostruct'

RSpec.describe 'Nodes', type: :feature do

  include MockBilling

  let(:user) { OpenStruct.new(email: 'user@sanger.ac.uk', groups: ['world']) }

  let(:user2) { OpenStruct.new(email: 'user2@sanger.ac.uk', groups: ['world']) }

  let!(:root) do
    n = build(:node, name: 'root')
    n.save!(validate: false)
    n
  end

  let!(:program1) do
    n = build(:node, name: 'program1', parent: root, owner_email: user.email)
    n.save!(validate: false)
    n
  end

  let!(:program2) do
    n = build(:node, name: 'program2', parent: root)
    n.save!(validate: false)
    n.permissions.create!(permitted: user.email, permission_type: :write)
    n
  end

  let!(:program3) do
    n = build(:node, name: 'program3', parent: root)
    n.save!(validate: false)
    n
  end

  let!(:proj) do
    create(:node, name: 'proj1', parent: program3, owner_email: user.email)
  end

  let!(:proj2) do
    create(:node, name: 'proj2', parent: program3, owner_email: user2.email)
  end

  let!(:proj_with_costcode) do
    create(:node, name: 'Proj with costcode', parent: proj2, owner_email: user.email, cost_code: valid_project_cost_code)
  end

  let!(:subproj) do
    create(:node, name: 'subproj', parent: proj_with_costcode, owner_email: user.email)
  end
  let!(:data_releases_strategies) do
    strategies = 5.times.map { |i| build(:data_release_strategy, name: "Study-#{i}") }
    strategies.reduce({}) do |memo, strategy|
      memo[strategy.id] = strategy
      memo
    end
  end

  before do
    allow(DataReleaseStrategyClient).to(
      receive(:find_strategies_by_user)
        .with(user.email)
        .and_return(data_releases_strategies.values)
    )

    allow_any_instance_of(JWTCredentials).to receive(:check_credentials)
    allow_any_instance_of(JWTCredentials).to receive(:current_user)
      .and_return(user)
  end

  context 'when I visit the Tree Hierarchy', js: true do
    before do
      visit tree_nodes_path
    end

    it 'shows the tree hierarchy' do
      expect(page.find_by_id('tree-hierarchy').visible?).to be(true)
    end

    it 'does show the edit panel' do
      expect(page.find(:css, '#edit-panel', visible: true)).to be_visible
    end

    describe 'clicking nodes' do
      context 'when I click a node' do

        before do
          page.find('div', class: 'node', text: root.name).click
        end

        it 'shows the edit panel' do
          expect(page.find_by_id('edit-panel').visible?).to be(true)
        end

        it 'shows selected node' do
          page.find('div', class: 'node', text: program1.name).click
          expect(page.find_by_id('selected-node').value).to eq program1.name
        end

      end

      context 'when I click a subproject' do

        it 'disables the "Add Node" button' do
          page.find('div', class: 'node', text: subproj.name).click
          expect(page.find_by_id('btn-add-nodes').disabled?).to be true
        end

      end

    end

    describe 'adding nodes' do
      it 'can add a new child node' do
        expect do
          page.find('div', class: 'node', text: program1.name).click
          page.fill_in 'New Node:', with: 'child'
          click_button 'Add Node'
          wait_for_ajax
        end.to change { program1.nodes.count }.by(1)
      end

    end

    describe 'deleting nodes' do
      context 'when a node has children' do
        before do
          page.find('div', class: 'node', text: root.name).click
        end

        it 'disables the delete button' do
          expect(page.find_by_id('btn-delete-nodes').disabled?).to be true
        end
      end

      context 'when a node has no children' do
        before do
          page.find('div', class: 'node', text: program1.name).click
        end

        it 'enables the delete button' do
          expect(page.find_by_id('btn-delete-nodes').disabled?).to be false
        end
      end

      it 'can delete a node lower down owned by the user' do
        page.find('div', class: 'node', text: proj.name).click
        click_button 'Delete'
        wait_for_ajax
        expect(proj.reload).not_to be_active
      end

      it 'cannot delete a node lower down owned by another user' do
        page.find('div', class: 'node', text: proj2.name).click
        expect(page).not_to have_button('Delete')
      end

      context 'when a node is the only one visible' do
        before do
          page.find('div', class: 'node', text: program2.name)
              .find('i', class: 'verticalEdge').trigger('click')
        end

        it 'reloads the whole tree' do
          expect(page.find('div', class: 'orgchart'))
            .to_not have_content(root.name)
          page.find('div', class: 'node', text: program2.name).click
          click_button 'Delete'
          wait_for_ajax
          expect(page.find('div', class: 'orgchart')).to have_content(root.name)
        end
      end
    end

    describe 'selecting a node' do
      context 'after selecting a node and filling in New Node' do
        before do
          page.find('div', class: 'node', text: program2.name).click
          page.fill_in 'New Node:', with: 'child'
        end

        it 'deselects the node' do
          expect(page.find_by_id('selected-node').value).to eq program2.name
          page.find('div', class: 'node', text: root.name).click
          expect(page.find_by_id('selected-node').value).to eq root.name
        end

        it 'clears the New Node input' do
          expect(page.find_by_id('new-node').value).to eq 'child'
          page.find('div', class: 'node', text: root.name).click
          expect(page.find_by_id('new-node').value).to eq ''
        end
      end
    end

    describe 'editing nodes' do
      context 'Double-clicking a node' do
        let(:modal) { page.find_by_id('editNodeModal') }

        let(:double_clicking) { 
          page.find('div', class: 'node', text: program1.name).double_click
          wait_for_ajax
        }

        it 'displays a modal with an edit form' do
          double_clicking

          expect(modal.visible?).to be(true)
          expect(modal.has_css?('form')).to be(true)
        end

        context 'when showing the modal' do
          context 'the data release strategy control' do

            it 'is showing the data release control' do
              double_clicking

              expect(modal.has_select?('Data release strategy')).to eq(true)
            end

            context 'the data release control' do
              
              context 'when obtaining the data release strategy for the user' do
                context 'when the selected data release strategy is not available for the user' do
                  context 'when the selected data release is not in the available list' do
                    let(:selected_data_release_strategy) { create(:data_release_strategy, name: 'a new one') }
                    before do
                      program1.update_attributes(data_release_strategy_id: selected_data_release_strategy.id)
                    end
                    it 'displays the value cached in the database' do
                      double_clicking

                      
                      expect(modal.has_content?(selected_data_release_strategy.name)).to eq(true)
                      save_and_open_page
                      expect(modal.has_select?('Data release strategy', with_options: [
                        data_releases_strategies.values.map(&:name), 
                        selected_data_release_strategy.name
                      ].flatten)).to eq(true)
                    end
                  end        
                end

                context 'when the selected data release is in the available list for the user' do
                  it 'displays the different choices in the control' do
                    double_clicking

                    expect(modal.has_select?('Data release strategy', 
                        with_options: data_releases_strategies.values.map(&:name))).to eq(true)
                  end
                end
              end
            end
          end
        end

      end

    end
  end

  describe '/nodes/tree' do
    before do
      visit tree_nodes_path
    end

    it 'shows me the tree view' do
      expect(page).to have_css('#tree')
    end
  end
end
