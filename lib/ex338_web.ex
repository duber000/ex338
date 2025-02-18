defmodule Ex338Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use Ex338.Web, :controller
      use Ex338.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      def all, do: Ex338.Repo.all(__MODULE__)
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, namespace: Ex338Web

      alias Ex338.Repo
      import Ecto
      import Ecto.Query

      alias Ex338Web.Router.Helpers, as: Routes
      import Ex338Web.Gettext
      import Phoenix.LiveView.Controller, only: [live_render: 3]
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/ex338_web/templates",
        namespace: Ex338Web

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      alias Ex338Web.Router.Helpers, as: Routes
      import Ex338Web.ErrorHelpers
      import Ex338Web.Gettext

      import Ex338Web.ViewHelpers
      import Phoenix.LiveView, only: [live_render: 2, live_render: 3]
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Ex338Web.Authorization, only: [authorize_admin: 2]
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel

      alias Ex338.Repo
      import Ecto
      import Ecto.Query
      import Ex338Web.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
