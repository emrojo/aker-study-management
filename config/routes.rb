Rails.application.routes.draw do

  root 'programs#show', id: 1

  resources :programs, only: [:show]
  resources :projects, only: [:show]
  resources :aims, only: [:show]
  resources :proposals, only: [:show]

  namespace :api do
    namespace :v1 do

      # https://github.com/cerebris/jsonapi-resources#routing
      jsonapi_resources :programs do
        jsonapi_relationships
      end

      jsonapi_resources :projects do
        jsonapi_relationships
      end

      jsonapi_resources :aims do
        jsonapi_relationships
      end

      jsonapi_resources :proposals

    end
  end

end
