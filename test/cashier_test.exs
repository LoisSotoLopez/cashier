defmodule CashierTest do
  use ExUnit.Case
  doctest Cashier

  use ExUnit.Case, async: true

  # TEST INITIALIZATION

  @gr1_price 311
  @sr1_price 500
  @cf1_price 1123

  setup :prices
  setup :discounts

  defp discounts(_context) do
    # One type of discount per product.
    Cashier.Discounts.register(%{
      "GR1" => {:buy_n_get_m, {1, 1}},
      "SR1" => {:bulk_n_fixed_price, {3, 450}},
      "CF1" => {:bulk_n_percent, {3, 2 / 3}}
    })

    :ok
  end

  defp prices(_context) do
    Cashier.Prices.set(%{
      "GR1" => @gr1_price,
      "SR1" => @sr1_price,
      "CF1" => @cf1_price
    })

    :ok
  end

  # CHALLENGE TESTS

  test "GR1,SR1,GR1,GR1,CF1 costs 2245" do
    assert 2245 == Cashier.calculate_basket_price(["GR1", "SR1", "GR1", "GR1", "CF1"])
  end

  test "GR1,GR1 costs 311" do
    assert 311 == Cashier.calculate_basket_price(["GR1", "GR1"])
  end

  test "SR1,SR1,GR1,SR1 costs 1661" do
    assert 1661 == Cashier.calculate_basket_price(["SR1", "SR1", "GR1", "SR1"])
  end

  test "GR1,CF1,SR1,CF1,CF1 costs 3057" do
    assert 3057 == Cashier.calculate_basket_price(["GR1", "CF1", "SR1", "CF1", "CF1"])
  end

  # ADDITIONAL TESTS
  test "Empty basket results in 0" do
    assert 0 == Cashier.calculate_basket_price([])
  end

  test "One item in basket returns its price" do
    assert @gr1_price == Cashier.calculate_basket_price(["GR1"])
    assert @sr1_price == Cashier.calculate_basket_price(["SR1"])
    assert @cf1_price == Cashier.calculate_basket_price(["CF1"])
  end

  test "Buy N get M free" do
    # "GR1" has the discount.  
    assert @gr1_price == Cashier.calculate_basket_price(["GR1", "GR1"])
    # "SR1" does not have the discount.
    assert @sr1_price + @sr1_price == Cashier.calculate_basket_price(["SR1", "SR1"])
  end

  test "Bulk discount to fixed price" do
    assert false
  end

  test "Bulk discount to percentage" do
    assert false
  end

  test "Order of products does not matter in final price" do
    all_items_ids = Cashier.Prices.get() |> Map.keys()
    basket = Enum.take_random(all_items_ids, 10 * length(all_items_ids))
    final_price = Cashier.calculate_basket_price(basket)
    assert final_price == Cashier.calculate_basket_price(Enum.shuffle(basket))
    assert final_price == Cashier.calculate_basket_price(Enum.shuffle(basket))
    assert final_price == Cashier.calculate_basket_price(Enum.shuffle(basket))
  end
end
