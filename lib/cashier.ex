defmodule Cashier do
  @moduledoc """
  Module implementing a cashier with a simple discount system. 
  """

  alias Cashier.{Discounts, Prices}

  @type item_id() :: String.t()
  @type price() :: float()
  @type percent() :: 1..100
  @type discounts() :: %{optional(item_id()) => discount_spec()}
  @type discount_spec() ::
          {:buy_n_get_m, {item_count(), non_neg_integer()}}
          | {:bulk_n_fixed_price, {item_count(), price()}}
          | {:bulk_n_percent, {item_count(), percent()}}
  @type item_count() :: non_neg_integer()

  @doc """
  Calculates the price of a list of items a.k.a. basket, considering the list of
  `item_id()`s passed as parameter, the discounts registered using the
  `Cashier.Discounts` and the items prices registered using the
  `Cashier.Prices`.

  ### Preconditions: 

  - Provided `item_id()`s need to have been previously registered with
  `Cashier.Discounts` module.

  ## Examples
      
      iex> Cashier.Prices.set(%{"GR1" => 311, "SR1" => 500, "CF1" => 1123})
      :ok
      iex> Cashier.calculate_basket_price(["GR1", "SR1", "CF1", "CF1"])
      3057

  """
  @spec calculate_basket_price(items) :: basket_price
        when items: [item_id()],
             basket_price: price()
  def calculate_basket_price([]) do
    0
  end

  def calculate_basket_price(items) do
    items
    |> Discounts.apply(Prices.get())
    |> List.foldl(0, fn {_item_id, price}, acc -> acc + price end)
  end
end
