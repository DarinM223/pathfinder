defmodule PathfinderWeb.Web.ActionView do
  def render("action.json", %{action: action}) do
    {action_name, params} = action
    params = Enum.map(params, fn
      tuple when is_tuple(tuple) -> Tuple.to_list(tuple)
      value -> value
    end)

    %{name: Atom.to_string(action_name),
      params: params}
  end
end
