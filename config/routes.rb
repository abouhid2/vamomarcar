Rails.application.routes.draw do
  devise_for :users

  post "switch_locale", to: "application#switch_locale"

  resources :groups do
    member do
      get :results
      post :join
      delete :leave
      delete :remove_member
    end
    resources :availabilities, only: [ :index, :create, :destroy ] do
      collection do
        delete :remove_range
        delete :batch_destroy
        get :preview_holidays
        post :add_all_holidays
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "groups#index"
end
