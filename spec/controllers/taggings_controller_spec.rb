require 'spec_helper'

describe TaggingsController do
  let(:user) { users(:owner) }

  before do
    log_in user
  end

  describe 'create' do
    context 'when a single entity is being tagged' do
      let(:entity) { workfiles(:public) }
      let(:params) { { :entity_id => entity.id, :entity_type => entity.class.name.underscore, :tag_names => tag_names } }
      let(:tag_names) { ['alpha', 'beta'] }

      it 'adds the tags' do
        post :create, params
        response.code.should == '201'
        entity.reload.tags.map(&:name).should =~ tag_names
      end

      it "removes tags" do
        entity.tag_list = ["alpha", "beta", "gamma"]
        entity.save!

        post :create, params
        response.code.should == '201'
        entity.reload.tags.map(&:name).should =~ tag_names
      end

      context 'with a dataset' do
        let(:entity) { datasets(:table) }

        it 'adds the tags' do
          post :create, params
          response.code.should == '201'
          entity.reload.tags.map(&:name).should =~ tag_names
        end
      end

      context 'when no tag names are provided' do
        let(:tag_names) { [] }

        it 'clears the list of tags on the model' do
          post :create, params
          response.code.should == '201'
          entity.reload.tags.should == []
        end
      end

      context 'with duplicate tag names' do
        let(:tag_names) { ['dupe', 'dupe'] }

        it 'sets the tag only once' do
          post :create, params
          response.code.should == '201'
          entity.reload.tags.length.should == 1
        end
      end

      context 'when the user cannot see the work file' do
        let(:user) { users(:no_collaborators) }
        let(:entity) { workfiles(:private) }

        it 'returns unauthorized' do
          post :create, params
          response.code.should == '403'
        end
      end

      context 'when tags are more than 100 characters' do
        let(:tag_names) { ["a" * 101] }

        it 'raise a validation error' do
          post :create, params
          response.should_not be_success
          decoded_errors.fields.base.should have_key :TOO_LONG
        end
      end

      context 'when saving the tag_list fails due uniqueness errors' do
        let(:tag_names) { %w{a b c} }
        let(:exception) { ActiveRecord::RecordInvalid.new(Tag.new) }

        before do
          mock(ModelMap).model_from_params(entity.class.name.underscore, entity.to_param) { entity }
          mock(entity, :tag_list=).with_any_args {
            raise exception
          }
        end

        it 'returns 422' do
          post :create, params
          response.code.should == '422'
        end

        it 'presents a specific error message' do
          post :create, params
          decoded_errors.record.should == "DUPLICATE_TAG"
        end

        context "when the uniqueness error is at the database level" do
          let(:exception) { ActiveRecord::RecordNotUnique.new('bang', StandardError.new('bang')) }

          it 'returns 422' do
            post :create, params
            response.code.should == '422'
          end

          it 'presents a specific error message' do
            post :create, params
            decoded_errors.record.should == "DUPLICATE_TAG"
          end
        end
      end

      describe 'when tags differ only in case' do
        let(:tag_names) { ['AlphaNotInFixtures', 'alphaNotInFixtures'] }

        it "sets a single tag on the workfile using the first tag's case" do
          post :create, params
          response.code.should == '201'
          entity.reload.tags.map(&:name).should == ['AlphaNotInFixtures']
        end
      end
    end
  end

  context 'when multiple entities are being tagged' do
    let(:first_entity) { workfiles(:public) }
    let(:second_entity) { datasets(:table) }
    let(:params) {
      { taggings: {
          "0" => {:entity_id => first_entity.id, :entity_type => first_entity.class.name.underscore, :tag_names => tag_names},
          "1" => {:entity_id => second_entity.id, :entity_type => second_entity.class.name.underscore, :tag_names => tag_names}}
      }
    }
    let(:tag_names) { ['alpha', 'beta'] }

    it 'adds the tags to each entity' do
      post :create, params
      response.code.should == '201'
      first_entity.reload.tags.map(&:name).should =~ tag_names
      second_entity.reload.tags.map(&:name).should =~ tag_names
    end
  end
end