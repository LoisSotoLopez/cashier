defmodule Cashier.Prices do
  @moduledoc """
  A module simulating a data storage
  """

  def set(price_list) do
    Application.put_env(__MODULE__, :price_list, price_list)
  end

  def get() do
    Application.get_env(__MODULE__, :price_list, [])
  end
end
