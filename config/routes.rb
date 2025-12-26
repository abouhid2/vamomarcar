Rails.application.routes.draw do
  devise_for :users

  post "switch_locale", to: "application#switch_locale"

  resources :groups do
    member do
      get :results
      get :share_invite
      post :join
      delete :leave
      delete :remove_member
      post :enable_invitations
      post :disable_invitations
      post :regenerate_invite_token
    end
    resources :availabilities, only: [ :index, :create, :destroy ] do
      collection do
        delete :remove_range
        delete :batch_destroy
        delete :remove_all
        get :preview_holidays
        post :add_all_holidays
        post :add_months
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "groups#index"
end
