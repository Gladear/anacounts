defmodule AppWeb.Router do
  use AppWeb, :router

  import AppWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {AppWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug AppWeb.Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AppWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  ## Authentication routes

  scope "/", AppWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", AppWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    get "/users/settings/balance", UserSettingsBalanceController, :edit
    post "/users/settings/balance", UserSettingsBalanceController, :update
    put "/users/settings/balance", UserSettingsBalanceController, :update
  end

  scope "/", AppWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end

  ## Books routes

  scope "/", AppWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :books, on_mount: [{AppWeb.UserAuth, :ensure_authenticated}] do
      live "/books", BookLive.Index, :index
      live "/books/new", BookLive.Form, :new
      live "/books/:book_id/edit", BookLive.Form, :edit

      live "/books/:book_id/invite", InvitationLive.Index, :index
      live "/books/:book_id/members", BookMemberLive.Index, :index
      live "/books/:book_id/transfers", MoneyTransferLive.Index, :index
      live "/books/:book_id/transfers/new", MoneyTransferLive.Form, :new
      live "/books/:book_id/transfers/:money_transfer_id/edit", MoneyTransferLive.Form, :edit
      live "/books/:book_id/balance", BalanceLive.Show, :show
    end
  end

  ## Metrics routes

  scope "/", AppWeb do
    get "/metrics/health_check", MetricsController, :health_check
  end

  # Other scopes may use custom stacks.
  # scope "/api", AppWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AppWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
