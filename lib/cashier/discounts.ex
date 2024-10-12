defmodule Cashier.Discounts do
  @moduledoc """
  Allows to register discounts and calculate new prices for lists of
  `Cashier.priced_items()`.
  """

  @doc """
    Allows to register a set of discounts. Following calls to `apply()` will use
    the registered discounts to calculate new prices for items.
  """
  @spec register(discounts) :: :ok
        when discounts: Cashier.discounts()
  def register(discounts) do
    Application.put_env(__MODULE__, :discounts, discounts)
  end

  @doc """
    Given a list of `priced_item()`s, calculates the price for each of them
    according to currently registered discounts.
  """
  @spec apply(items, item_prices) :: priced_items
        when items: [Cashier.item_id()],
             item_prices: %{Cashier.item_id() => Cashier.price()},
             priced_items: [{Cashier.item_id(), Cashier.price()}]
  def apply(items, item_prices) do
    discounts = Application.get_env(__MODULE__, :discounts, [])

    items
    |> Enum.frequencies()
    |> Enum.map(fn {item_id, count} ->
      base_price = Map.get(item_prices, item_id)
      discount = Map.get(discounts, item_id, :none)
      price_with_discount(discount, item_id, count, base_price)
    end)
    |> List.flatten()
  end

  defp price_with_discount(:none, item_id, count, base_price) do
    for _ <- 1..count, do: {item_id, base_price}
  end

  # Not enought items to apply the discount
  defp price_with_discount(
         {:buy_n_get_m, {count_required, _got_free}},
         item_id,
         count,
         base_price
       )
       when count < count_required do
    for _ <- 1..count, do: {item_id, base_price}
  end

  # Enought items to apply the discount once.
  defp price_with_discount(
         {:buy_n_get_m, {_count_required, got_free}},
         item_id,
         count,
         base_price
       )
       when count - 1 <= got_free do
    [{item_id, base_price} | for(_ <- 1..(count - 1), do: {item_id, 0})]
  end

  # Enough items to apply the discount once and try to apply one more time
  defp price_with_discount(
         {:buy_n_get_m, {_count_required, got_free}} = discount,
         item_id,
         count,
         base_price
       ) do
    [{item_id, base_price} | for(_ <- 1..got_free, do: {item_id, 0})] ++
      price_with_discount(discount, item_id, count - 1 - got_free, base_price)
  end

  # Not enought items to apply discount
  defp price_with_discount(
         {:bulk_n_fixed_price, {count_required, _discounted_price}},
         item_id,
         count,
         base_price
       )
       when count < count_required do
    for _ <- 1..count, do: {item_id, base_price}
  end

  # Enought items to apply discount
  defp price_with_discount(
         {:bulk_n_fixed_price, {_count_required, discounted_price}},
         item_id,
         count,
         _base_price
       ) do
    for _ <- 1..count, do: {item_id, discounted_price}
  end

  # Not enought items to apply discount
  defp price_with_discount(
         {:bulk_n_percent, {count_required, _percent}},
         item_id,
         count,
         base_price
       )
       when count < count_required do
    for _ <- 1..count, do: {item_id, base_price}
  end

  # Enought items to apply discount
  defp price_with_discount(
         {:bulk_n_percent, {_count_required, percent}},
         item_id,
         count,
         base_price
       ) do
    for _ <- 1..count, do: {item_id, base_price * percent}
  end
end
