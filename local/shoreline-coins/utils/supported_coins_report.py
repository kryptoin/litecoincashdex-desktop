#!/usr/bin/env python3
import os
import json


script_path = os.path.abspath(os.path.dirname(__file__))
os.chdir(script_path)

def get_coins_data(coins_file=f"{script_path}/coins_config.json"):
    with open(coins_file, "r") as f:
        coins_data = json.load(f)
    return coins_data

def get_supported_coins_list(
    coins_data, key="coin",
    group_by=None, exclude_testnet=True
):
    if group_by:
        supported_coins = {}
        for ticker, data in coins_data.items():
            if exclude_testnet and "testnet" in data:
                continue
            if group_by in data:
                if data[group_by] not in supported_coins:
                    supported_coins.update({data[group_by]: []})
                if key in data:
                    supported_coins[data[group_by]].append(data[key])

        for i in supported_coins:
            supported_coins[i] = sorted(supported_coins[i])
    else:
        supported_coins = []
        for ticker, data in coins_data.items():
            if key in data:
                supported_coins.append(data[key])
        supported_coins = sorted(supported_coins)
    return supported_coins

if __name__ == "__main__":
    coins_data = get_coins_data()
    supported_coins = get_supported_coins_list(coins_data, group_by="type")
    for i, coins in supported_coins.items():
        print(f"{i}: {coins}")
